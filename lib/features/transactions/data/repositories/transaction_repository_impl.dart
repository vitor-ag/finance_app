import 'package:drift/drift.dart';
import '../../../../data/local/database.dart';
import '../../domain/entities/transaction.dart';
import '../../domain/repositories/transaction_repository.dart';

class TransactionRepositoryImpl implements TransactionRepository {
  final AppDatabase db;

  TransactionRepositoryImpl(this.db);

  Transaction _mapRow(TransactionRow row) {
    return Transaction(
      id: row.id,
      type: row.type,
      amount: row.amount,
      date: row.date,
      accountId: row.accountId,
      destinationAccountId: row.destinationAccountId,
      categoryId: row.categoryId,
      description: row.description,
      status: row.status,
      createdAt: row.createdAt,
      deletedAt: row.deletedAt,
    );
  }

  @override
  Stream<List<Transaction>> watchAllTransactions() {
    return (db.select(db.transactions)
          ..where((tbl) => tbl.deletedAt.isNull()))
        .watch()
        .map((rows) => rows.map(_mapRow).toList());
  }

  @override
  Future<Transaction?> getTransactionById(int id) async {
    final row = await (db.select(db.transactions)
          ..where((tbl) => tbl.id.equals(id)))
        .getSingleOrNull();
    return row == null ? null : _mapRow(row);
  }

  @override
  Future<int> createTransaction(Transaction transaction) {
    // Runs insert + balance updates as a single atomic operation.
    return db.transaction(() async {
      final id = await db.into(db.transactions).insert(
            TransactionsCompanion.insert(
              type: transaction.type,
              amount: transaction.amount,
              date: transaction.date,
              accountId: transaction.accountId,
              destinationAccountId: Value(transaction.destinationAccountId),
              categoryId: Value(transaction.categoryId),
              description: Value(transaction.description),
              status: Value(transaction.status),
            ),
          );

      await _applyBalanceEffect(transaction);

      return id;
    });
  }

  @override
  Future<void> deleteTransaction(int id) {
    return db.transaction(() async {
      final row = await (db.select(db.transactions)
            ..where((tbl) => tbl.id.equals(id)))
          .getSingleOrNull();

      if (row == null) return;

      // Reverts the balance effect before soft-deleting.
      await _applyBalanceEffect(_mapRow(row), reverse: true);

      await (db.update(db.transactions)..where((tbl) => tbl.id.equals(id)))
          .write(TransactionsCompanion(deletedAt: Value(DateTime.now())));
    });
  }

  /// Applies (or reverses, when [reverse] is true) the balance impact
  /// of a transaction on the account(s) involved.
  Future<void> _applyBalanceEffect(
    Transaction transaction, {
    bool reverse = false,
  }) async {
    final sign = reverse ? -1 : 1;

    switch (transaction.type) {
      case 'income':
        await _adjustAccountBalance(
          transaction.accountId,
          transaction.amount * sign,
        );
        break;

      case 'expense':
        await _adjustAccountBalance(
          transaction.accountId,
          -transaction.amount * sign,
        );
        break;

      case 'transfer':
        await _adjustAccountBalance(
          transaction.accountId,
          -transaction.amount * sign,
        );
        if (transaction.destinationAccountId != null) {
          await _adjustAccountBalance(
            transaction.destinationAccountId!,
            transaction.amount * sign,
          );
        }
        break;
    }
  }

  Future<void> _adjustAccountBalance(int accountId, double delta) async {
    final account = await (db.select(db.accounts)
          ..where((tbl) => tbl.id.equals(accountId)))
        .getSingle();

    await (db.update(db.accounts)..where((tbl) => tbl.id.equals(accountId)))
        .write(
      AccountsCompanion(
        currentBalance: Value(account.currentBalance + delta),
      ),
    );
  }
}