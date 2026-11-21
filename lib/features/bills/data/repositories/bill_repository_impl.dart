import 'package:drift/drift.dart';

import '../../../../core/calendar.dart';
import '../../../../core/money.dart';
import '../../../../data/local/database.dart';
import '../../../transactions/data/repositories/transaction_repository_impl.dart';
import '../../../transactions/domain/entities/transaction.dart';
import '../../domain/entities/bill.dart';
import '../../domain/repositories/bill_repository.dart';

class BillRepositoryImpl implements BillRepository {
  final AppDatabase db;
  final TransactionRepositoryImpl _transactions;

  BillRepositoryImpl(this.db) : _transactions = TransactionRepositoryImpl(db);

  Bill _mapRow(BillRow row) {
    return Bill(
      id: row.id,
      name: row.name,
      categoryId: row.categoryId,
      amountCents: row.amountCents,
      dueDate: row.dueDate,
      billType: row.billType,
      status: row.status,
      paymentAccountId: row.paymentAccountId,
      paidTransactionId: row.paidTransactionId,
      repeatDay: row.repeatDay,
      previousBillId: row.previousBillId,
      notes: row.notes,
      createdAt: row.createdAt,
    );
  }

  @override
  Stream<List<Bill>> watchAllBills() {
    return db
        .select(db.bills)
        .watch()
        .map((rows) => rows.map(_mapRow).toList());
  }

  @override
  Future<Bill?> getBillById(int id) async {
    final row = await (db.select(
      db.bills,
    )..where((tbl) => tbl.id.equals(id))).getSingleOrNull();
    return row == null ? null : _mapRow(row);
  }

  @override
  Future<int> createBill(Bill bill) {
    validatePositiveCents(bill.amountCents);
    return db.transaction(() async {
      final id = await db
          .into(db.bills)
          .insert(
            BillsCompanion.insert(
              name: bill.name,
              categoryId: Value(bill.categoryId),
              amountCents: bill.amountCents,
              dueDate: bill.dueDate,
              billType: bill.billType,
              repeatDay: Value(
                bill.billType == 'recurring' ? bill.dueDate.day : null,
              ),
              notes: Value(bill.notes),
            ),
          );
      await _generateSeries(id, calendarDate(DateTime.now()));
      return id;
    });
  }

  @override
  Future<void> updateBill(Bill bill) {
    validatePositiveCents(bill.amountCents);
    final id = bill.id!;
    return db.transaction(() async {
      final previous = await getBillById(id);
      if (previous == null || previous.status != 'pending') {
        throw StateError('Apenas contas pendentes podem ser editadas.');
      }
      if (previous.billType == 'recurring' &&
          bill.billType != previous.billType) {
        throw StateError('Para interromper uma série, use Parar repetição.');
      }
      final due = calendarDate(bill.dueDate);
      var repeatDay = previous.repeatDay;
      if (due != calendarDate(previous.dueDate)) {
        await _validateSeriesDate(previous, due);
        if (repeatDay != null) repeatDay = due.day;
      }
      if (previous.billType != 'recurring' && bill.billType == 'recurring') {
        repeatDay = due.day;
      }
      await (db.update(db.bills)..where((tbl) => tbl.id.equals(id))).write(
        BillsCompanion(
          name: Value(bill.name),
          categoryId: Value(bill.categoryId),
          amountCents: Value(bill.amountCents),
          dueDate: Value(bill.dueDate),
          billType: Value(bill.billType),
          repeatDay: Value(repeatDay),
          notes: Value(bill.notes),
        ),
      );
      await _generateSeries(id, calendarDate(DateTime.now()));
    });
  }

  Future<void> _validateSeriesDate(Bill bill, DateTime due) async {
    if (bill.billType != 'recurring') return;
    final earlierId = bill.previousBillId;
    final earlier = earlierId == null ? null : await getBillById(earlierId);
    final later = await _nextBill(bill.id!);
    if ((earlier != null && !due.isAfter(calendarDate(earlier.dueDate))) ||
        (later != null && !due.isBefore(calendarDate(later.dueDate)))) {
      throw StateError(
        'O vencimento deve ficar entre as demais contas da série.',
      );
    }
  }

  Future<BillRow?> _nextBill(int id) => (db.select(
    db.bills,
  )..where((tbl) => tbl.previousBillId.equals(id))).getSingleOrNull();

  @override
  Future<void> generateDueBills() async {
    final today = calendarDate(DateTime.now());
    final schedules =
        await (db.select(db.bills)..where(
              (tbl) =>
                  tbl.repeatDay.isNotNull() &
                  tbl.dueDate.isSmallerThanValue(
                    DateTime(today.year, today.month, today.day + 1),
                  ),
            ))
            .get();
    for (final schedule in schedules) {
      await db.transaction(() => _generateSeries(schedule.id, today));
    }
  }

  Future<void> _generateSeries(int id, DateTime today) async {
    final template = await getBillById(id);
    final repeatDay = template?.repeatDay;
    if (template == null || repeatDay == null) return;
    var currentId = id;
    var due = calendarDate(template.dueDate);
    while (!due.isAfter(today)) {
      due = dateWithClampedDay(due.year, due.month + 1, repeatDay);
      await _clearRepeatDay(currentId);
      currentId = await db
          .into(db.bills)
          .insert(
            BillsCompanion.insert(
              name: template.name,
              categoryId: Value(template.categoryId),
              amountCents: template.amountCents,
              dueDate: due,
              billType: 'recurring',
              repeatDay: Value(repeatDay),
              previousBillId: Value(currentId),
              notes: Value(template.notes),
            ),
          );
    }
  }

  @override
  Future<void> stopRepeating(int id) {
    return db.transaction(() async {
      var currentId = id;
      var next = await _nextBill(currentId);
      while (next != null) {
        currentId = next.id;
        next = await _nextBill(currentId);
      }
      await _clearRepeatDay(currentId);
    });
  }

  Future<void> _clearRepeatDay(int id) {
    return (db.update(db.bills)..where((tbl) => tbl.id.equals(id))).write(
      const BillsCompanion(repeatDay: Value(null)),
    );
  }

  @override
  Future<void> markAsPaid(int billId, {required int paymentAccountId}) {
    return db.transaction(() async {
      final bill = await getBillById(billId);
      if (bill == null || bill.status != 'pending') return;

      final now = DateTime.now();
      final transactionId = await _transactions.createTransaction(
        Transaction(
          type: 'expense',
          amountCents: bill.amountCents,
          date: now,
          accountId: paymentAccountId,
          categoryId: bill.categoryId,
          description: 'Pagamento: ${bill.name}',
          createdAt: now,
        ),
      );

      await (db.update(db.bills)..where((tbl) => tbl.id.equals(billId))).write(
        BillsCompanion(
          status: const Value('paid'),
          paymentAccountId: Value(paymentAccountId),
          paidTransactionId: Value(transactionId),
        ),
      );
    });
  }

  @override
  Future<void> cancelBill(int id) {
    return (db.update(db.bills)
          ..where((tbl) => tbl.id.equals(id) & tbl.status.equals('pending')))
        .write(const BillsCompanion(status: Value('cancelled')));
  }
}
