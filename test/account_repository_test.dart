import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:finance_app/data/local/database.dart';
import 'package:finance_app/features/accounts/data/repositories/account_repository_impl.dart';
import 'package:finance_app/features/accounts/domain/entities/account.dart';

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
}