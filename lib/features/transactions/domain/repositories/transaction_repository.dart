import '../entities/transaction.dart';

abstract class TransactionRepository {
  Stream<List<Transaction>> watchAllTransactions();
  Stream<List<Transaction>> watchDeletedTransactions();
  Future<Transaction?> getTransactionById(int id);

  /// Creates a transaction AND applies its balance effect atomically.
  Future<int> createTransaction(Transaction transaction);

  Future<void> updateTransaction(Transaction transaction);

  /// Soft-deletes a transaction AND reverts its balance effect atomically.
  Future<void> deleteTransaction(int id);

  Future<void> restoreTransaction(int id);
}
