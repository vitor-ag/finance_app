import 'package:drift/native.dart';
import 'package:finance_app/data/local/database.dart';
import 'package:finance_app/features/backup/data/backup_snapshot.dart';
import 'package:finance_app/features/backup/data/local_backup.dart';
import 'package:finance_app/features/budgets/budget_data.dart';
import 'package:finance_app/features/reports/finance_summary.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'budget carryover uses only the remaining amount of the previous month',
    () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(db.close);
      final category = await db
          .into(db.categories)
          .insert(
            CategoriesCompanion.insert(name: 'Alimentação', type: 'expense'),
          );
      final repository = BudgetRepository(db);
      final september = DateTime(2026, 9);
      final october = DateTime(2026, 10);
      await repository.save(
        category: category,
        month: september,
        limit: 10000,
        carryOver: true,
      );
      await repository.save(
        category: category,
        month: october,
        limit: 20000,
        carryOver: false,
      );
      final history = FinanceHistory()
        ..add(september, 'expense', 6000, category)
        ..add(october, 'expense', 2000, category)
        ..add(october, 'income', 5000, null)
        ..add(october, 'transfer', 4500, null)
        ..add(october, 'card_payment', 2000, null);
      final records = await repository.watch().first;
      final budget = BudgetProgress.forMonth(records, october, history).single;
      expect(budget.limit, BigInt.from(24000));
      expect(budget.remaining, BigInt.from(22000));
      final summary = history.summarize(monthPeriod(october));
      expect(summary.result, BigInt.from(3000));
      expect(summary.records, 2);
    },
  );

  test('local encrypted backup restores a populated database', () async {
    final source = AppDatabase.forTesting(NativeDatabase.memory());
    final target = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(source.close);
    addTearDown(target.close);
    await source
        .into(source.accounts)
        .insert(AccountsCompanion.insert(name: 'Carteira', type: 'cash'));
    final create = LocalBackup(BackupDatabase(source));
    final restore = LocalBackup(BackupDatabase(target));
    const password = 'uma senha de teste';
    final bytes = await create.create(password);
    expect(bytes, isNotEmpty);
    final prepared = await restore.prepare(bytes, password);
    expect(prepared.snapshot.transactionCount, 0);
    await restore.restore(prepared);
    expect((await target.select(target.accounts).getSingle()).name, 'Carteira');
    await expectLater(
      restore.prepare(bytes, 'senha diferente'),
      throwsA(isA<BackupProblem>()),
    );
    expect((await target.select(target.accounts).getSingle()).name, 'Carteira');
  });
}
