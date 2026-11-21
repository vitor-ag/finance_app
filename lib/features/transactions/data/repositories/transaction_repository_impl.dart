import 'dart:convert';

import 'package:drift/drift.dart';

import '../../../../core/money.dart';

import '../../../../data/local/database.dart';
import '../../domain/entities/transaction.dart';
import '../../domain/entities/transaction_revision.dart';
import '../../domain/repositories/transaction_repository.dart';

class TransactionRepositoryImpl implements TransactionRepository {
  final AppDatabase db;

  TransactionRepositoryImpl(this.db);

  Transaction _mapRow(TransactionRow row) {
    return Transaction(
      id: row.id,
      type: row.type,
      amountCents: row.amountCents,
      date: row.date,
      accountId: row.accountId,
      destinationAccountId: row.destinationAccountId,
      categoryId: row.categoryId,
      description: row.description,
      incomeSource: row.incomeSource,
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
  Stream<List<Transaction>> watchTransactionsInPeriod(
    DateTime start,
    DateTime end,
  ) {
    return (db.select(db.transactions)..where(
          (entry) =>
              entry.deletedAt.isNull() &
              entry.date.isBiggerOrEqualValue(start) &
              entry.date.isSmallerThanValue(end),
        ))
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
  Future<List<TransactionRevision>> listRevisions(int id) async {
    final rows =
        await (db.select(db.transactionRevisions)
              ..where((tbl) => tbl.transactionId.equals(id))
              ..orderBy([(tbl) => OrderingTerm.desc(tbl.id)]))
            .get();
    return rows.map((row) {
      final data = jsonDecode(row.snapshot) as Map<String, dynamic>;
      return TransactionRevision(
        row.action,
        row.recordedAt,
        Transaction(
          id: row.transactionId,
          type: data['type'] as String,
          amountCents: data['amountCents'] as int,
          date: DateTime.parse(data['date'] as String),
          accountId: data['accountId'] as int,
          destinationAccountId: data['destinationAccountId'] as int?,
          categoryId: data['categoryId'] as int?,
          description: data['description'] as String?,
          incomeSource: data['incomeSource'] as String?,
          status: data['status'] as String,
          recurrenceId: data['recurrenceId'] as int?,
          deletedAt: DateTime.tryParse(data['deletedAt'] as String? ?? ''),
          createdAt: DateTime.parse(data['createdAt'] as String),
        ),
      );
    }).toList();
  }

  Future<void> _recordRevision(String action, Transaction entry) async {
    await db
        .into(db.transactionRevisions)
        .insert(
          TransactionRevisionsCompanion.insert(
            transactionId: entry.id!,
            action: action,
            snapshot: jsonEncode({
              'type': entry.type,
              'amountCents': entry.amountCents,
              'date': entry.date.toIso8601String(),
              'accountId': entry.accountId,
              'destinationAccountId': entry.destinationAccountId,
              'categoryId': entry.categoryId,
              'description': entry.description,
              'incomeSource': entry.incomeSource,
              'status': entry.status,
              'recurrenceId': entry.recurrenceId,
              'createdAt': entry.createdAt.toIso8601String(),
              'deletedAt': entry.deletedAt?.toIso8601String(),
            }),
          ),
        );
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
              amountCents: transaction.amountCents,
              date: transaction.date,
              accountId: transaction.accountId,
              destinationAccountId: Value(transaction.destinationAccountId),
              categoryId: Value(transaction.categoryId),
              description: Value(transaction.description),
              incomeSource: Value(_incomeSource(transaction)),
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

      await _recordRevision('edit', previous);
      await (db.update(
        db.transactions,
      )..where((tbl) => tbl.id.equals(id))).write(
        TransactionsCompanion(
          type: Value(transaction.type),
          amountCents: Value(transaction.amountCents),
          date: Value(transaction.date),
          accountId: Value(transaction.accountId),
          destinationAccountId: Value(transaction.destinationAccountId),
          categoryId: Value(transaction.categoryId),
          description: Value(transaction.description),
          incomeSource: Value(_incomeSource(transaction)),
          status: Value(transaction.status),
        ),
      );
      await _applyBalanceEffect(transaction, replacing: previous);
    });
  }

  @override
  Future<void> deleteTransaction(int id) {
    return db.transaction(() async {
      final entry = await getTransactionById(id);
      if (entry == null || entry.deletedAt != null) return;
      await _ensureNotBillPayment(id);
      await _recordRevision('delete', entry);
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
      await _recordRevision('restore', entry);
      await _applyBalanceEffect(entry);
      await (db.update(db.transactions)..where((tbl) => tbl.id.equals(id)))
          .write(const TransactionsCompanion(deletedAt: Value(null)));
    });
  }

  Future<void> _ensureNotBillPayment(int transactionId) async {
    final cardPayment =
        await (db.select(db.cardPayments)
              ..where((row) => row.transactionId.equals(transactionId))
              ..limit(1))
            .getSingleOrNull();
    if (cardPayment != null) {
      throw StateError(
        'Este lançamento está vinculado ao pagamento de uma fatura.',
      );
    }
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
    validatePositiveCents(transaction.amountCents);
    if (!const {'income', 'expense', 'transfer'}.contains(transaction.type)) {
      throw StateError('Selecione um tipo de lançamento válido.');
    }
    if (!const {'pending', 'paid', 'cancelled'}.contains(transaction.status)) {
      throw StateError('Selecione um status válido.');
    }
    if (transaction.categoryId case final categoryId?) {
      final category = await (db.select(
        db.categories,
      )..where((row) => row.id.equals(categoryId))).getSingleOrNull();
      if (category == null ||
          category.type != transaction.type ||
          (!category.isActive && categoryId != previous?.categoryId)) {
        throw StateError('Selecione uma categoria válida.');
      }
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

  String? _incomeSource(Transaction entry) {
    final source = entry.incomeSource?.trim();
    return entry.type == 'income' && source != null && source.isNotEmpty
        ? source
        : null;
  }

  Future<void> _applyBalanceEffect(
    Transaction transaction, {
    bool reverse = false,
    Transaction? replacing,
  }) async {
    final deltas = <int, int>{};
    void addDelta(int id, int cents) {
      deltas.update(id, (delta) => delta + cents, ifAbsent: () => cents);
    }

    void addEntry(Transaction entry, int sign) {
      if (entry.status != 'paid') return;
      final cents = entry.amountCents * sign;
      switch (entry.type) {
        case 'income':
          addDelta(entry.accountId, cents);
        case 'expense':
          addDelta(entry.accountId, -cents);
        case 'transfer':
          addDelta(entry.accountId, -cents);
          if (entry.destinationAccountId case final destination?) {
            addDelta(destination, cents);
          }
      }
    }

    if (replacing != null) addEntry(replacing, -1);
    addEntry(transaction, reverse ? -1 : 1);
    for (final delta in deltas.entries) {
      if (delta.value != 0) await _adjustAccountBalance(delta.key, delta.value);
    }
  }

  Future<void> _adjustAccountBalance(int accountId, int delta) async {
    final account = await (db.select(
      db.accounts,
    )..where((tbl) => tbl.id.equals(accountId))).getSingle();

    final balance = account.currentBalanceCents + delta;
    validateBalanceCents(balance);
    await (db.update(db.accounts)..where((tbl) => tbl.id.equals(accountId)))
        .write(AccountsCompanion(currentBalanceCents: Value(balance)));
  }
}
