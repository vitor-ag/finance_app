import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:finance_app/data/local/database.dart';
import 'package:finance_app/features/accounts/data/repositories/account_repository_impl.dart';
import 'package:finance_app/features/accounts/domain/entities/account.dart';
import 'package:finance_app/features/transactions/data/repositories/transaction_repository_impl.dart';
import 'package:finance_app/features/transactions/domain/entities/transaction.dart';

void main() {
  late AppDatabase db;
  late AccountRepositoryImpl accountRepo;
  late TransactionRepositoryImpl transactionRepo;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    accountRepo = AccountRepositoryImpl(db);
    transactionRepo = TransactionRepositoryImpl(db);
  });

  tearDown(() async => db.close());

  test('pending entries affect balance only when paid', () async {
    final now = DateTime.now();
    final accountId = await accountRepo.createAccount(
      Account(
        name: 'Carteira',
        type: 'cash',
        initialBalanceCents: 0,
        currentBalanceCents: 0,
        createdAt: now,
      ),
    );
    final id = await transactionRepo.createTransaction(
      Transaction(
        type: 'expense',
        amountCents: 5000,
        date: now,
        accountId: accountId,
        createdAt: now,
        status: 'pending',
      ),
    );
    expect(
      (await accountRepo.getAccountById(accountId))!.currentBalanceCents,
      0,
    );
    final entry = (await transactionRepo.getTransactionById(id))!;
    await transactionRepo.updateTransaction(entry.copyWith(status: 'paid'));
    expect(
      (await accountRepo.getAccountById(accountId))!.currentBalanceCents,
      -5000,
    );
    await transactionRepo.deleteTransaction(id);
    expect(
      (await accountRepo.getAccountById(accountId))!.currentBalanceCents,
      0,
    );
  });

  test('income increases account balance', () async {
    final accountId = await accountRepo.createAccount(
      Account(
        name: 'Nubank',
        type: 'digital',
        initialBalanceCents: 10000,
        currentBalanceCents: 10000,
        createdAt: DateTime.now(),
      ),
    );

    await transactionRepo.createTransaction(
      Transaction(
        type: 'income',
        amountCents: 5000,
        date: DateTime.now(),
        accountId: accountId,
        createdAt: DateTime.now(),
      ),
    );

    final account = await accountRepo.getAccountById(accountId);
    expect(account!.currentBalanceCents, 15000);
  });

  test('expense decreases account balance', () async {
    final accountId = await accountRepo.createAccount(
      Account(
        name: 'Nubank',
        type: 'digital',
        initialBalanceCents: 10000,
        currentBalanceCents: 10000,
        createdAt: DateTime.now(),
      ),
    );

    await transactionRepo.createTransaction(
      Transaction(
        type: 'expense',
        amountCents: 3000,
        date: DateTime.now(),
        accountId: accountId,
        createdAt: DateTime.now(),
      ),
    );

    final account = await accountRepo.getAccountById(accountId);
    expect(account!.currentBalanceCents, 7000);
  });

  test('transfer moves balance between accounts', () async {
    final originId = await accountRepo.createAccount(
      Account(
        name: 'Conta Principal',
        type: 'corrente',
        initialBalanceCents: 50000,
        currentBalanceCents: 50000,
        createdAt: DateTime.now(),
      ),
    );

    final destinationId = await accountRepo.createAccount(
      Account(
        name: 'Investimentos',
        type: 'investimento',
        initialBalanceCents: 0,
        currentBalanceCents: 0,
        createdAt: DateTime.now(),
      ),
    );

    await transactionRepo.createTransaction(
      Transaction(
        type: 'transfer',
        amountCents: 10000,
        date: DateTime.now(),
        accountId: originId,
        destinationAccountId: destinationId,
        createdAt: DateTime.now(),
      ),
    );

    final origin = await accountRepo.getAccountById(originId);
    final destination = await accountRepo.getAccountById(destinationId);

    expect(origin!.currentBalanceCents, 40000);
    expect(destination!.currentBalanceCents, 10000);
  });

  test('deleting a transaction reverts its balance effect', () async {
    final accountId = await accountRepo.createAccount(
      Account(
        name: 'Nubank',
        type: 'digital',
        initialBalanceCents: 10000,
        currentBalanceCents: 10000,
        createdAt: DateTime.now(),
      ),
    );

    final transactionId = await transactionRepo.createTransaction(
      Transaction(
        type: 'expense',
        amountCents: 4000,
        date: DateTime.now(),
        accountId: accountId,
        createdAt: DateTime.now(),
      ),
    );

    await transactionRepo.deleteTransaction(transactionId);

    final account = await accountRepo.getAccountById(accountId);
    expect(account!.currentBalanceCents, 10000);
  });

  test(
    'editing a transfer replaces both balance effects and restores once',
    () async {
      final now = DateTime.now();
      Future<int> account(String name) => accountRepo.createAccount(
        Account(
          name: name,
          type: 'cash',
          initialBalanceCents: 10000,
          currentBalanceCents: 10000,
          createdAt: now,
        ),
      );
      final origin = await account('Origem');
      final destination = await account('Destino');
      final other = await account('Nova conta');
      Future<List<int>> balances() async => [
        for (final id in [origin, destination, other])
          (await accountRepo.getAccountById(id))!.currentBalanceCents,
      ];
      final id = await transactionRepo.createTransaction(
        Transaction(
          type: 'transfer',
          amountCents: 4000,
          date: now,
          accountId: origin,
          destinationAccountId: destination,
          description: 'Texto antigo',
          createdAt: now,
        ),
      );
      final original = (await transactionRepo.getTransactionById(id))!;
      await expectLater(
        transactionRepo.updateTransaction(
          original.copyWith(destinationAccountId: origin),
        ),
        throwsStateError,
      );
      expect(await balances(), [6000, 14000, 10000]);

      final revisedDate = now.subtract(const Duration(days: 2));
      await transactionRepo.updateTransaction(
        Transaction(
          id: id,
          type: 'transfer',
          amountCents: 2500,
          date: revisedDate,
          accountId: other,
          destinationAccountId: origin,
          createdAt: now,
        ),
      );
      expect(await balances(), [12500, 10000, 7500]);
      final edited = (await transactionRepo.getTransactionById(id))!;
      expect(edited.description, isNull);
      expect(edited.date.day, revisedDate.day);

      await Future.wait([
        transactionRepo.deleteTransaction(id),
        transactionRepo.deleteTransaction(id),
      ]);
      expect(await balances(), [10000, 10000, 10000]);
      expect(await transactionRepo.watchAllTransactions().first, isEmpty);
      expect(
        (await transactionRepo.watchDeletedTransactions().first).single.id,
        id,
      );

      await Future.wait([
        transactionRepo.restoreTransaction(id),
        transactionRepo.restoreTransaction(id),
      ]);
      expect(await balances(), [12500, 10000, 7500]);
      expect(await transactionRepo.watchDeletedTransactions().first, isEmpty);
      final revisions = await transactionRepo.listRevisions(id);
      expect(revisions.map((revision) => revision.action), [
        'restore',
        'delete',
        'edit',
      ]);
      expect(revisions.last.previous.amountCents, 4000);
      expect(revisions.last.previous.destinationAccountId, destination);
      expect(revisions.last.previous.description, 'Texto antigo');
    },
  );

  test('reuses exact centavos through editing and restoration', () async {
    final now = DateTime.now();
    final id = await accountRepo.createAccount(
      Account(
        name: 'Carteira',
        type: 'cash',
        initialBalanceCents: 0,
        currentBalanceCents: 0,
        createdAt: now,
      ),
    );
    final amount = Transaction(
      type: 'income',
      amountCents: 10,
      date: now,
      accountId: id,
      incomeSource: ' Cliente ',
      createdAt: now,
    );
    final entryId = await transactionRepo.createTransaction(amount);
    await transactionRepo.createTransaction(amount.copyWith(amountCents: 20));
    expect((await accountRepo.getAccountById(id))!.currentBalanceCents, 30);
    final entry = (await transactionRepo.getTransactionById(entryId))!;
    expect(entry.incomeSource, 'Cliente');
    await transactionRepo.updateTransaction(entry.copyWith(amountCents: 1));
    await transactionRepo.deleteTransaction(entryId);
    await transactionRepo.restoreTransaction(entryId);
    expect((await accountRepo.getAccountById(id))!.currentBalanceCents, 21);
    final revisions = await transactionRepo.listRevisions(entryId);
    expect(revisions.last.previous.incomeSource, 'Cliente');
  });
}
