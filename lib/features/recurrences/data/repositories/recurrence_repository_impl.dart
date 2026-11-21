import 'package:drift/drift.dart';

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
      amount: row.amount,
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
  Future<int> createRecurrence(Recurrence recurrence) {
    return db
        .into(db.recurrences)
        .insert(
          RecurrencesCompanion.insert(
            name: recurrence.name,
            type: recurrence.type,
            amount: recurrence.amount,
            accountId: recurrence.accountId,
            destinationAccountId: Value(recurrence.destinationAccountId),
            categoryId: Value(recurrence.categoryId),
            description: Value(recurrence.description),
            frequency: recurrence.frequency,
            dayOfMonth: Value(recurrence.dayOfMonth),
            weekday: Value(recurrence.weekday),
            startDate: recurrence.startDate,
            endDate: Value(recurrence.endDate),
            maxOccurrences: Value(recurrence.maxOccurrences),
            nextOccurrenceDate: recurrence.startDate,
          ),
        );
  }

  @override
  Future<void> pauseRecurrence(int id) {
    return (db.update(db.recurrences)..where((tbl) => tbl.id.equals(id))).write(
      const RecurrencesCompanion(status: Value('paused')),
    );
  }

  @override
  Future<void> resumeRecurrence(int id) {
    return (db.update(db.recurrences)..where((tbl) => tbl.id.equals(id))).write(
      const RecurrencesCompanion(status: Value('active')),
    );
  }

  @override
  Future<void> cancelRecurrence(int id) {
    return (db.update(db.recurrences)..where((tbl) => tbl.id.equals(id))).write(
      const RecurrencesCompanion(status: Value('cancelled')),
    );
  }

  @override
  Future<void> generateDueOccurrences() async {
    final now = DateTime.now();

    final recurrences = db.recurrences;
    final dueIds =
        await (db.selectOnly(recurrences)
              ..addColumns([recurrences.id])
              ..where(
                recurrences.status.equals('active') &
                    recurrences.nextOccurrenceDate.isSmallerOrEqualValue(now),
              ))
            .map((row) => row.read(recurrences.id)!)
            .get();

    for (final id in dueIds) {
      await db.transaction(() async {
        // Re-read the schedule inside the transaction in case another call
        // advanced it or the user paused it after we selected the IDs.
        final r =
            await (db.select(recurrences)..where(
                  (tbl) => tbl.id.equals(id) & tbl.status.equals('active'),
                ))
                .getSingleOrNull();
        if (r == null || r.nextOccurrenceDate.isAfter(now)) return;

        var nextDate = r.nextOccurrenceDate;
        var generatedCount = r.generatedCount;
        var finished = false;

        while (!nextDate.isAfter(now)) {
          if (r.endDate != null && nextDate.isAfter(r.endDate!)) {
            finished = true;
            break;
          }
          if (r.maxOccurrences != null && generatedCount >= r.maxOccurrences!) {
            finished = true;
            break;
          }

          await _createOccurrence(r, nextDate);
          generatedCount++;
          nextDate = _advance(nextDate, r.frequency, r.dayOfMonth, r.weekday);
        }

        await (db.update(
          db.recurrences,
        )..where((tbl) => tbl.id.equals(r.id))).write(
          RecurrencesCompanion(
            nextOccurrenceDate: Value(nextDate),
            generatedCount: Value(generatedCount),
            status: Value(finished ? 'finished' : 'active'),
          ),
        );
      });
    }
  }

  Future<void> _createOccurrence(RecurrenceRow r, DateTime date) async {
    await _transactions.createTransaction(
      Transaction(
        type: r.type,
        amount: r.amount,
        date: date,
        accountId: r.accountId,
        destinationAccountId: r.destinationAccountId,
        categoryId: r.categoryId,
        description: r.description ?? r.name,
        recurrenceId: r.id,
        createdAt: DateTime.now(),
      ),
    );
  }

  DateTime _advance(
    DateTime current,
    String frequency,
    int? dayOfMonth,
    int? weekday,
  ) {
    switch (frequency) {
      case 'weekly':
        return current.add(const Duration(days: 7));

      case 'yearly':
        return DateTime(current.year + 1, current.month, current.day);

      case 'monthly':
      default:
        final targetMonth = current.month == 12 ? 1 : current.month + 1;
        final targetYear = current.month == 12
            ? current.year + 1
            : current.year;
        final day = dayOfMonth ?? current.day;
        final lastDayOfTargetMonth = DateTime(
          targetYear,
          targetMonth + 1,
          0,
        ).day;
        return DateTime(
          targetYear,
          targetMonth,
          day > lastDayOfTargetMonth ? lastDayOfTargetMonth : day,
        );
    }
  }
}
