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

  test('income increases account balance', () async {
    final accountId = await accountRepo.createAccount(
      Account(
        name: 'Nubank',
        type: 'digital',
        initialBalance: 100,
        currentBalance: 100,
        createdAt: DateTime.now(),
      ),
    );

    await transactionRepo.createTransaction(
      Transaction(
        type: 'income',
        amount: 50,
        date: DateTime.now(),
        accountId: accountId,
        createdAt: DateTime.now(),
      ),
    );

    final account = await accountRepo.getAccountById(accountId);
    expect(account!.currentBalance, 150);
  });

  test('expense decreases account balance', () async {
    final accountId = await accountRepo.createAccount(
      Account(
        name: 'Nubank',
        type: 'digital',
        initialBalance: 100,
        currentBalance: 100,
        createdAt: DateTime.now(),
      ),
    );

    await transactionRepo.createTransaction(
      Transaction(
        type: 'expense',
        amount: 30,
        date: DateTime.now(),
        accountId: accountId,
        createdAt: DateTime.now(),
      ),
    );

    final account = await accountRepo.getAccountById(accountId);
    expect(account!.currentBalance, 70);
  });

  test('transfer moves balance between accounts', () async {
    final originId = await accountRepo.createAccount(
      Account(
        name: 'Conta Principal',
        type: 'corrente',
        initialBalance: 500,
        currentBalance: 500,
        createdAt: DateTime.now(),
      ),
    );

    final destinationId = await accountRepo.createAccount(
      Account(
        name: 'Investimentos',
        type: 'investimento',
        initialBalance: 0,
        currentBalance: 0,
        createdAt: DateTime.now(),
      ),
    );

    await transactionRepo.createTransaction(
      Transaction(
        type: 'transfer',
        amount: 100,
        date: DateTime.now(),
        accountId: originId,
        destinationAccountId: destinationId,
        createdAt: DateTime.now(),
      ),
    );

    final origin = await accountRepo.getAccountById(originId);
    final destination = await accountRepo.getAccountById(destinationId);

    expect(origin!.currentBalance, 400);
    expect(destination!.currentBalance, 100);
  });

  test('deleting a transaction reverts its balance effect', () async {
    final accountId = await accountRepo.createAccount(
      Account(
        name: 'Nubank',
        type: 'digital',
        initialBalance: 100,
        currentBalance: 100,
        createdAt: DateTime.now(),
      ),
    );

    final transactionId = await transactionRepo.createTransaction(
      Transaction(
        type: 'expense',
        amount: 40,
        date: DateTime.now(),
        accountId: accountId,
        createdAt: DateTime.now(),
      ),
    );

    await transactionRepo.deleteTransaction(transactionId);

    final account = await accountRepo.getAccountById(accountId);
    expect(account!.currentBalance, 100);
  });
}