import '../entities/transaction.dart';
import '../entities/transaction_revision.dart';

abstract class TransactionRepository {
  Stream<List<Transaction>> watchAllTransactions();
  Stream<List<Transaction>> watchTransactionsInPeriod(
    DateTime start,
    DateTime end,
  );
  Stream<List<Transaction>> watchDeletedTransactions();
  Future<Transaction?> getTransactionById(int id);
  Future<List<TransactionRevision>> listRevisions(int id);

  /// Creates a transaction AND applies its balance effect atomically.
  Future<int> createTransaction(Transaction transaction);

  Future<void> updateTransaction(Transaction transaction);

  /// Soft-deletes a transaction AND reverts its balance effect atomically.
  Future<void> deleteTransaction(int id);
  Future<void> deleteRecurrenceEntries(int recurrenceId, {DateTime? from});

  Future<void> restoreTransaction(int id);
}
