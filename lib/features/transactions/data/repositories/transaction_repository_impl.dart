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
      recurrenceId: row.recurrenceId,
      createdAt: row.createdAt,
      deletedAt: row.deletedAt,
    );
  }

  @override
  Stream<List<Transaction>> watchAllTransactions() {
    return (db.select(db.transactions)
          ..where((tbl) => tbl.deletedAt.isNull())
          ..orderBy([
            (tbl) => OrderingTerm.desc(tbl.date),
            (tbl) => OrderingTerm.desc(tbl.id),
          ]))
        .watch()
        .map((rows) => rows.map(_mapRow).toList());
  }

  @override
  Stream<List<Transaction>> watchDeletedTransactions() {
    return (db.select(db.transactions)
          ..where((tbl) => tbl.deletedAt.isNotNull())
          ..orderBy([
            (tbl) => OrderingTerm.desc(tbl.deletedAt),
            (tbl) => OrderingTerm.desc(tbl.id),
          ]))
        .watch()
        .map((rows) => rows.map(_mapRow).toList());
  }

  @override
  Future<Transaction?> getTransactionById(int id) async {
    final row = await (db.select(
      db.transactions,
    )..where((tbl) => tbl.id.equals(id))).getSingleOrNull();
    return row == null ? null : _mapRow(row);
  }

  @override
  Future<int> createTransaction(Transaction transaction) {
    // Runs insert + balance updates as a single atomic operation.
    return db.transaction(() async {
      await _validate(transaction);
      final id = await db
          .into(db.transactions)
          .insert(
            TransactionsCompanion.insert(
              type: transaction.type,
              amount: transaction.amount,
              date: transaction.date,
              accountId: transaction.accountId,
              destinationAccountId: Value(transaction.destinationAccountId),
              categoryId: Value(transaction.categoryId),
              description: Value(transaction.description),
              status: Value(transaction.status),
              recurrenceId: Value(transaction.recurrenceId),
            ),
          );

      await _applyBalanceEffect(transaction);

      return id;
    });
  }

  @override
  Future<void> updateTransaction(Transaction transaction) {
    final id = transaction.id!;
    return db.transaction(() async {
      final previous = await getTransactionById(id);
      if (previous == null || previous.deletedAt != null) {
        throw StateError(
          'Este lançamento não está mais disponível no histórico.',
        );
      }
      await _ensureNotBillPayment(id);
      await _validate(transaction, previous: previous);

      await _applyBalanceEffect(previous, reverse: true);
      await (db.update(
        db.transactions,
      )..where((tbl) => tbl.id.equals(id))).write(
        TransactionsCompanion(
          type: Value(transaction.type),
          amount: Value(transaction.amount),
          date: Value(transaction.date),
          accountId: Value(transaction.accountId),
          destinationAccountId: Value(transaction.destinationAccountId),
          categoryId: Value(transaction.categoryId),
          description: Value(transaction.description),
        ),
      );
      await _applyBalanceEffect(transaction);
    });
  }

  @override
  Future<void> deleteTransaction(int id) {
    return db.transaction(() async {
      final entry = await getTransactionById(id);
      if (entry == null || entry.deletedAt != null) return;
      await _ensureNotBillPayment(id);
      await _applyBalanceEffect(entry, reverse: true);
      await (db.update(db.transactions)..where((tbl) => tbl.id.equals(id)))
          .write(TransactionsCompanion(deletedAt: Value(DateTime.now())));
    });
  }

  @override
  Future<void> restoreTransaction(int id) {
    return db.transaction(() async {
      final entry = await getTransactionById(id);
      if (entry == null || entry.deletedAt == null) return;
      await _applyBalanceEffect(entry);
      await (db.update(db.transactions)..where((tbl) => tbl.id.equals(id)))
          .write(const TransactionsCompanion(deletedAt: Value(null)));
    });
  }

  Future<void> _ensureNotBillPayment(int transactionId) async {
    final bill =
        await (db.select(db.bills)
              ..where((tbl) => tbl.paidTransactionId.equals(transactionId))
              ..limit(1))
            .getSingleOrNull();
    if (bill != null) {
      throw StateError(
        'Este lançamento está vinculado ao pagamento de uma conta.',
      );
    }
  }

  Future<void> _validate(
    Transaction transaction, {
    Transaction? previous,
  }) async {
    if (!transaction.amount.isFinite || transaction.amount <= 0) {
      throw StateError('Informe um valor maior que zero.');
    }
    if (!const {'income', 'expense', 'transfer'}.contains(transaction.type)) {
      throw StateError('Selecione um tipo de lançamento válido.');
    }
    final destination = transaction.destinationAccountId;
    if (transaction.type == 'transfer' &&
        (destination == null || destination == transaction.accountId)) {
      throw StateError('Selecione contas diferentes para origem e destino.');
    }
    for (final id in [transaction.accountId, destination].nonNulls) {
      if (id == previous?.accountId || id == previous?.destinationAccountId) {
        continue;
      }
      final account = await (db.select(
        db.accounts,
      )..where((tbl) => tbl.id.equals(id))).getSingleOrNull();
      if (account == null || !account.isActive) {
        throw StateError('Selecione uma conta ativa.');
      }
    }
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
    final account = await (db.select(
      db.accounts,
    )..where((tbl) => tbl.id.equals(accountId))).getSingle();

    await (db.update(
      db.accounts,
    )..where((tbl) => tbl.id.equals(accountId))).write(
      AccountsCompanion(currentBalance: Value(account.currentBalance + delta)),
    );
  }
}
