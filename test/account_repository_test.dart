import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:finance_app/data/local/database.dart';
import 'package:finance_app/features/accounts/data/repositories/account_repository_impl.dart';
import 'package:finance_app/features/accounts/domain/entities/account.dart';
import 'package:finance_app/features/transactions/data/repositories/transaction_repository_impl.dart';
import 'package:finance_app/features/transactions/domain/entities/transaction.dart';

void main() {
  test('create and read an account', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    final repo = AccountRepositoryImpl(db);

    final id = await repo.createAccount(
      Account(
        name: 'Nubank',
        type: 'digital',
        initialBalance: 100,
        currentBalance: 100,
        createdAt: DateTime.now(),
      ),
    );

    final account = await repo.getAccountById(id);

    expect(account, isNotNull);
    expect(account!.name, 'Nubank');
    expect(account.currentBalance, 100);

    await db.close();
  });

  test('editing an account preserves the latest balance and archiving keeps history', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    final accounts = AccountRepositoryImpl(db);
    final transactions = TransactionRepositoryImpl(db);
    final now = DateTime.now();
    final id = await accounts.createAccount(
      Account(
        name: 'Conta',
        type: 'checking',
        initialBalance: 100,
        currentBalance: 100,
        createdAt: now,
      ),
    );
    final stale = (await accounts.getAccountById(id))!;
    final income = Transaction(
      type: 'income',
      amount: 50,
      date: now,
      accountId: id,
      createdAt: now,
    );
    await transactions.createTransaction(income);
    await accounts.updateAccount(stale.copyWith(name: 'Conta principal'));
    await accounts.archiveAccount(id);

    final archived = (await accounts.getAccountById(id))!;
    expect(archived.name, 'Conta principal');
    expect(archived.currentBalance, 150);
    expect(archived.isActive, isFalse);
    await expectLater(transactions.createTransaction(income), throwsStateError);
    expect(
      (await transactions.watchAllTransactions().first).single.accountId,
      id,
    );
  });
}
