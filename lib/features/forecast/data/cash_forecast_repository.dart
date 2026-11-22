import 'package:drift/drift.dart';

import '../../../core/calendar.dart';
import '../../../data/local/database.dart';
import '../../recurrences/domain/entities/recurrence.dart';
import '../domain/cash_forecast.dart';

class CashForecastRepository {
  const CashForecastRepository(this.db);

  final AppDatabase db;

  Stream<CashForecast> watch(DateTime today) {
    final start = calendarDate(today);
    final end = forecastDateAt(start, cashForecastDays);
    // Read every source in one snapshot. Settling a bill or a statement
    // changes the balance and removes the obligation in the same commit.
    return db
        .customSelect(
          'SELECT 1',
          readsFrom: {
            db.accounts,
            db.transactions,
            db.bills,
            db.recurrences,
            db.creditCards,
            db.cardPurchases,
            db.cardInstallments,
          },
        )
        .watch()
        .asyncMap(
          (_) => db.transaction(() async {
            final accounts =
                await (db.select(db.accounts)
                      ..where((row) => row.isActive.equals(true))
                      ..orderBy([(row) => OrderingTerm.asc(row.name)]))
                    .get();
            return CashForecast(
              today: start,
              accounts: {
                for (final row in accounts)
                  row.id: (name: row.name, balance: row.currentBalanceCents),
              },
              events: [
                ...await _scheduled(end),
                ...await _bills(end),
                ...await _recurrences(end),
                ...await _statements(end),
              ],
            );
          }),
        );
  }

  Future<List<CashEvent>> _scheduled(DateTime end) {
    final t = db.transactions;
    return (db.selectOnly(t)
          ..addColumns([
            t.type,
            t.date,
            t.description,
            t.amountCents,
            t.accountId,
            t.destinationAccountId,
          ])
          ..where(
            t.status.equals('pending') &
                t.deletedAt.isNull() &
                t.type.isIn(['income', 'expense', 'transfer']) &
                t.date.isSmallerThanValue(end),
          ))
        .map((row) {
          final type = row.read(t.type)!;
          return _entry(
            title:
                row.read(t.description) ??
                switch (type) {
                  'income' => 'Receita agendada',
                  'transfer' => 'Transferência agendada',
                  _ => 'Despesa agendada',
                },
            type: type,
            date: row.read(t.date)!,
            cents: row.read(t.amountCents)!,
            accountId: row.read(t.accountId)!,
            destinationAccountId: row.read(t.destinationAccountId),
            source: CashEventSource.scheduled,
          );
        })
        .get();
  }

  Future<List<CashEvent>> _bills(DateTime end) async {
    final rows =
        await (db.select(db.bills)..where(
              (bill) =>
                  bill.dueDate.isSmallerThanValue(end) &
                  (bill.status.equals('pending') | bill.repeatDay.isNotNull()),
            ))
            .get();
    final events = <CashEvent>[];
    for (final bill in rows) {
      var date = calendarDate(bill.dueDate);
      final delta = -BigInt.from(bill.amountCents);
      if (bill.status == 'pending') {
        events.add(
          CashEvent(
            title: bill.name,
            date: date,
            delta: delta,
            accountId: bill.paymentAccountId,
            source: CashEventSource.bill,
          ),
        );
      }
      // Only the last materialized bill in a series has a repetition day.
      if (bill.repeatDay case final day?) {
        date = dateWithClampedDay(date.year, date.month + 1, day);
        while (date.isBefore(end)) {
          events.add(
            CashEvent(
              title: bill.name,
              date: date,
              delta: delta,
              source: CashEventSource.repeatingBill,
            ),
          );
          date = dateWithClampedDay(date.year, date.month + 1, day);
        }
      }
    }
    return events;
  }

  Future<List<CashEvent>> _recurrences(DateTime end) async {
    final rows =
        await (db.select(db.recurrences)..where(
              (row) =>
                  row.status.equals('active') &
                  row.nextOccurrenceDate.isSmallerThanValue(end),
            ))
            .get();
    final events = <CashEvent>[];
    for (final recurrence in rows) {
      var date = calendarDate(recurrence.nextOccurrenceDate);
      var count = recurrence.generatedCount;
      final lastDate = recurrence.endDate;
      final limit = recurrence.maxOccurrences;
      while (date.isBefore(end) &&
          (lastDate == null || !date.isAfter(calendarDate(lastDate))) &&
          (limit == null || count < limit)) {
        events.add(
          _entry(
            title: recurrence.description ?? recurrence.name,
            type: recurrence.type,
            date: date,
            cents: recurrence.amountCents,
            accountId: recurrence.accountId,
            destinationAccountId: recurrence.destinationAccountId,
            source: CashEventSource.recurrence,
          ),
        );
        date = nextRecurrenceDate(
          date,
          recurrence.frequency,
          recurrence.dayOfMonth ?? recurrence.startDate.day,
        );
        count++;
      }
    }
    return events;
  }

  Future<List<CashEvent>> _statements(DateTime end) async {
    final i = db.cardInstallments;
    final p = db.cardPurchases;
    final c = db.creditCards;
    final rows =
        await (db.selectOnly(i)
              ..addColumns([
                c.id,
                c.name,
                i.closingDate,
                i.dueDate,
                i.amountCents,
              ])
              ..join([
                innerJoin(p, p.id.equalsExp(i.purchaseId), useColumns: false),
                innerJoin(c, c.id.equalsExp(p.cardId), useColumns: false),
              ])
              ..where(i.paymentId.isNull() & i.dueDate.isSmallerThanValue(end)))
            .get();
    final statements =
        <({int id, String card, DateTime closing, DateTime due}), BigInt>{};
    for (final row in rows) {
      final key = (
        id: row.read(c.id)!,
        card: row.read(c.name)!,
        closing: calendarDate(row.read(i.closingDate)!),
        due: calendarDate(row.read(i.dueDate)!),
      );
      final cents = BigInt.from(row.read(i.amountCents)!);
      statements.update(key, (amount) => amount + cents, ifAbsent: () => cents);
    }
    return [
      for (final MapEntry(key: statement, value: cents) in statements.entries)
        CashEvent(
          title: statement.card,
          date: statement.due,
          delta: -cents,
          source: CashEventSource.statement,
          cardId: statement.id,
        ),
    ];
  }

  CashEvent _entry({
    required String title,
    required String type,
    required DateTime date,
    required int cents,
    required int accountId,
    required int? destinationAccountId,
    required CashEventSource source,
  }) => CashEvent(
    title: title,
    date: calendarDate(date),
    delta: BigInt.from(type == 'income' ? cents : -cents),
    accountId: accountId,
    destinationAccountId: type == 'transfer' ? destinationAccountId : null,
    source: source,
  );
}
