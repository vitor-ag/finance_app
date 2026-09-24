import 'package:drift/drift.dart';
import '../../../../data/local/database.dart';
import '../../domain/entities/bill.dart';
import '../../domain/repositories/bill_repository.dart';

class BillRepositoryImpl implements BillRepository {
  final AppDatabase db;

  BillRepositoryImpl(this.db);

  Bill _mapRow(BillRow row) {
    return Bill(
      id: row.id,
      name: row.name,
      categoryId: row.categoryId,
      amount: row.amount,
      dueDate: row.dueDate,
      billType: row.billType,
      status: row.status,
      paymentAccountId: row.paymentAccountId,
      paidTransactionId: row.paidTransactionId,
      notes: row.notes,
      createdAt: row.createdAt,
    );
  }

  @override
  Stream<List<Bill>> watchAllBills() {
    return db.select(db.bills).watch().map(
          (rows) => rows.map(_mapRow).toList(),
        );
  }

  @override
  Future<Bill?> getBillById(int id) async {
    final row = await (db.select(db.bills)..where((tbl) => tbl.id.equals(id)))
        .getSingleOrNull();
    return row == null ? null : _mapRow(row);
  }

  @override
  Future<int> createBill(Bill bill) {
    return db.into(db.bills).insert(
          BillsCompanion.insert(
            name: bill.name,
            categoryId: Value(bill.categoryId),
            amount: bill.amount,
            dueDate: bill.dueDate,
            billType: bill.billType,
            notes: Value(bill.notes),
          ),
        );
  }

  @override
  Future<void> markAsPaid(int billId, {required int paymentAccountId}) {
    return db.transaction(() async {
      final bill = await getBillById(billId);
      if (bill == null || bill.status != 'pending') return;

      // Create the actual expense transaction (this also updates the
      // account balance, via TransactionRepository's own balance logic).
      final transactionId = await db.into(db.transactions).insert(
            TransactionsCompanion.insert(
              type: 'expense',
              amount: bill.amount,
              date: DateTime.now(),
              accountId: paymentAccountId,
              categoryId: Value(bill.categoryId),
              description: Value('Pagamento: ${bill.name}'),
            ),
          );

      final account = await (db.select(db.accounts)
            ..where((tbl) => tbl.id.equals(paymentAccountId)))
          .getSingle();

      await (db.update(db.accounts)
            ..where((tbl) => tbl.id.equals(paymentAccountId)))
          .write(
        AccountsCompanion(
          currentBalance: Value(account.currentBalance - bill.amount),
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
    return (db.update(db.bills)..where((tbl) => tbl.id.equals(id)))
        .write(const BillsCompanion(status: Value('cancelled')));
  }
}