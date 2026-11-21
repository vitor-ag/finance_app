import '../entities/bill.dart';

abstract class BillRepository {
  Stream<List<Bill>> watchAllBills();
  Future<Bill?> getBillById(int id);
  Future<int> createBill(Bill bill);
  Future<void> updateBill(Bill bill);
  Future<void> generateDueBills();
  Future<void> stopRepeating(int id);

  /// Marks a bill as paid AND creates the corresponding expense
  /// transaction atomically, so the balance drops exactly once.
  Future<void> markAsPaid(int billId, {required int paymentAccountId});

  Future<void> cancelBill(int id);
}
