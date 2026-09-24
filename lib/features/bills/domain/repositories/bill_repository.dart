import '../entities/bill.dart';

abstract class BillRepository {
  Stream<List<Bill>> watchAllBills();
  Future<Bill?> getBillById(int id);
  Future<int> createBill(Bill bill);

  /// Marks a bill as paid AND creates the corresponding expense
  /// transaction atomically, so the balance drops exactly once.
  Future<void> markAsPaid(int billId, {required int paymentAccountId});

  Future<void> cancelBill(int id);
}