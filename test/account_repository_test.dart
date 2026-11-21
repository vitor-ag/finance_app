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
        initialBalanceCents: 10000,
        currentBalanceCents: 10000,
        createdAt: DateTime.now(),
      ),
    );

    final account = await repo.getAccountById(id);

    expect(account, isNotNull);
    expect(account!.name, 'Nubank');
    expect(account.currentBalanceCents, 10000);

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
        initialBalanceCents: 10000,
        currentBalanceCents: 10000,
        createdAt: now,
      ),
    );
    final stale = (await accounts.getAccountById(id))!;
    final income = Transaction(
      type: 'income',
      amountCents: 5000,
      date: now,
      accountId: id,
      createdAt: now,
    );
    await transactions.createTransaction(income);
    await accounts.updateAccount(stale.copyWith(name: 'Conta principal'));
    await accounts.archiveAccount(id);

    final archived = (await accounts.getAccountById(id))!;
    expect(archived.name, 'Conta principal');
    expect(archived.currentBalanceCents, 15000);
    expect(archived.isActive, isFalse);
    await expectLater(transactions.createTransaction(income), throwsStateError);
    expect(
      (await transactions.watchAllTransactions().first).single.accountId,
      id,
    );
  });
}
