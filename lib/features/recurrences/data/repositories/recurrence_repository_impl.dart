import 'package:drift/drift.dart';

import '../../../../core/calendar.dart';
import '../../../../core/money.dart';

import '../../../../data/local/database.dart';
import '../../../transactions/data/repositories/transaction_repository_impl.dart';
import '../../../transactions/domain/entities/transaction.dart';
import '../../domain/entities/recurrence.dart';
import '../../domain/repositories/recurrence_repository.dart';

class RecurrenceRepositoryImpl implements RecurrenceRepository {
  final AppDatabase db;
  final TransactionRepositoryImpl _transactions;

  RecurrenceRepositoryImpl(this.db)
    : _transactions = TransactionRepositoryImpl(db);

  Recurrence _mapRow(RecurrenceRow row) {
    return Recurrence(
      id: row.id,
      name: row.name,
      type: row.type,
      amountCents: row.amountCents,
      accountId: row.accountId,
      destinationAccountId: row.destinationAccountId,
      categoryId: row.categoryId,
      description: row.description,
      frequency: row.frequency,
      dayOfMonth: row.dayOfMonth,
      weekday: row.weekday,
      startDate: row.startDate,
      endDate: row.endDate,
      maxOccurrences: row.maxOccurrences,
      generatedCount: row.generatedCount,
      nextOccurrenceDate: row.nextOccurrenceDate,
      status: row.status,
      createdAt: row.createdAt,
    );
  }

  @override
  Stream<List<Recurrence>> watchAllRecurrences() {
    return db
        .select(db.recurrences)
        .watch()
        .map((rows) => rows.map(_mapRow).toList());
  }

  @override
  Future<int> createRecurrence(Recurrence recurrence, {Transaction? first}) {
    validatePositiveCents(recurrence.amountCents);
    final start = calendarDate(recurrence.startDate);
    final end = recurrence.endDate == null
        ? null
        : calendarDate(recurrence.endDate!);
    if ((end != null && end.isBefore(start)) ||
        (recurrence.maxOccurrences != null && recurrence.maxOccurrences! < 1)) {
      throw StateError(
        'Informe uma data final e um limite de ocorrências válidos.',
      );
    }
    if (!const {'weekly', 'monthly', 'yearly'}.contains(recurrence.frequency) ||
        !const {'income', 'expense', 'transfer'}.contains(recurrence.type) ||
        (recurrence.type == 'transfer' &&
            (recurrence.destinationAccountId == null ||
                recurrence.destinationAccountId == recurrence.accountId))) {
      throw StateError('Informe uma recorrência válida.');
    }
    final day = recurrence.dayOfMonth ?? start.day;
    if (day < 1 || day > 31) throw StateError('Informe um dia válido.');
    return db.transaction(() async {
      for (final id in [
        recurrence.accountId,
        recurrence.destinationAccountId,
      ].nonNulls) {
        final account = await (db.select(
          db.accounts,
        )..where((tbl) => tbl.id.equals(id))).getSingleOrNull();
        if (account == null || !account.isActive) {
          throw StateError('Selecione uma conta ativa.');
        }
      }
      final id = await db
          .into(db.recurrences)
          .insert(
            RecurrencesCompanion.insert(
              name: recurrence.name,
              type: recurrence.type,
              amountCents: recurrence.amountCents,
              accountId: recurrence.accountId,
              destinationAccountId: Value(recurrence.destinationAccountId),
              categoryId: Value(recurrence.categoryId),
              description: Value(recurrence.description),
              frequency: recurrence.frequency,
              dayOfMonth: Value(day),
              weekday: Value(recurrence.weekday),
              startDate: start,
              endDate: Value(end),
              maxOccurrences: Value(recurrence.maxOccurrences),
              nextOccurrenceDate: first == null
                  ? start
                  : _advance(start, recurrence.frequency, day),
              generatedCount: Value(first == null ? 0 : 1),
              entryStatus: Value(first?.status ?? 'paid'),
              note: Value(first?.note),
              incomeSource: Value(first?.incomeSource),
            ),
          );
      if (first != null) {
        await _transactions.createTransaction(first.copyWith(recurrenceId: id));
      } else {
        await _generateRecurrence(id, calendarDate(DateTime.now()));
      }
      return id;
    });
  }

  @override
  Future<void> updateRecurrence(Recurrence recurrence) {
    validatePositiveCents(recurrence.amountCents);
    final end = recurrence.endDate;
    if (end != null &&
        calendarDate(end).isBefore(calendarDate(recurrence.startDate))) {
      throw StateError(
        'O término precisa ser posterior ao início da recorrência.',
      );
    }
    return (db.update(db.recurrences)..where(
          (row) =>
              row.id.equals(recurrence.id!) &
              row.status.isIn(['active', 'paused']),
        ))
        .write(
          RecurrencesCompanion(
            name: Value(recurrence.name.trim()),
            amountCents: Value(recurrence.amountCents),
            description: Value(recurrence.description),
            endDate: Value(end == null ? null : calendarDate(end)),
          ),
        );
  }

  @override
  Future<void> pauseRecurrence(int id) {
    return (db.update(db.recurrences)
          ..where((tbl) => tbl.id.equals(id) & tbl.status.equals('active')))
        .write(const RecurrencesCompanion(status: Value('paused')));
  }

  @override
  Future<void> resumeRecurrence(int id) {
    return db.transaction(() async {
      final resumed =
          await (db.update(db.recurrences)..where(
                (tbl) => tbl.id.equals(id) & tbl.status.equals('paused'),
              ))
              .write(const RecurrencesCompanion(status: Value('active')));
      if (resumed != 0) {
        await _generateRecurrence(id, calendarDate(DateTime.now()));
      }
    });
  }

  @override
  Future<void> cancelRecurrence(int id) {
    return (db.update(db.recurrences)..where((tbl) => tbl.id.equals(id))).write(
      const RecurrencesCompanion(status: Value('cancelled')),
    );
  }

  @override
  Future<void> generateDueOccurrences() async {
    final today = calendarDate(DateTime.now());
    final tomorrow = DateTime(today.year, today.month, today.day + 1);

    final recurrences = db.recurrences;
    final dueIds =
        await (db.selectOnly(recurrences)
              ..addColumns([recurrences.id])
              ..where(
                recurrences.status.equals('active') &
                    recurrences.nextOccurrenceDate.isSmallerThanValue(tomorrow),
              ))
            .map((row) => row.read(recurrences.id)!)
            .get();

    for (final id in dueIds) {
      await db.transaction(() => _generateRecurrence(id, today));
    }
  }

  Future<void> _generateRecurrence(int id, DateTime today) async {
    // Re-read the schedule inside the transaction in case another call
    // advanced it or the user paused it after we selected the IDs.
    final r =
        await (db.select(db.recurrences)
              ..where((tbl) => tbl.id.equals(id) & tbl.status.equals('active')))
            .getSingleOrNull();
    if (r == null) return;

    var nextDate = calendarDate(r.nextOccurrenceDate);
    if (nextDate.isAfter(today)) return;
    final end = r.endDate == null ? null : calendarDate(r.endDate!);
    final limit = r.maxOccurrences;
    var generatedCount = r.generatedCount;
    bool finished() =>
        (end != null && nextDate.isAfter(end)) ||
        (limit != null && generatedCount >= limit);

    while (!nextDate.isAfter(today) && !finished()) {
      await _createOccurrence(r, nextDate);
      generatedCount++;
      nextDate = _advance(
        nextDate,
        r.frequency,
        r.dayOfMonth ?? r.startDate.day,
      );
    }

    await (db.update(
      db.recurrences,
    )..where((tbl) => tbl.id.equals(r.id))).write(
      RecurrencesCompanion(
        nextOccurrenceDate: Value(nextDate),
        generatedCount: Value(generatedCount),
        status: Value(finished() ? 'finished' : 'active'),
      ),
    );
  }

  Future<void> _createOccurrence(RecurrenceRow r, DateTime date) async {
    await _transactions.createTransaction(
      Transaction(
        type: r.type,
        amountCents: r.amountCents,
        date: date,
        accountId: r.accountId,
        destinationAccountId: r.destinationAccountId,
        categoryId: r.categoryId,
        description: r.description ?? r.name,
        note: r.note,
        incomeSource: r.incomeSource,
        status: r.entryStatus,
        recurrenceId: r.id,
        createdAt: DateTime.now(),
      ),
    );
  }

  DateTime _advance(DateTime current, String frequency, int dayOfMonth) {
    switch (frequency) {
      case 'weekly':
        return DateTime(current.year, current.month, current.day + 7);

      case 'yearly':
        return dateWithClampedDay(current.year + 1, current.month, dayOfMonth);

      case 'monthly':
      default:
        return dateWithClampedDay(current.year, current.month + 1, dayOfMonth);
    }
  }
}
