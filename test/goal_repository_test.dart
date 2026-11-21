import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:finance_app/data/local/database.dart';
import 'package:finance_app/features/goals/data/repositories/goal_repository_impl.dart';
import 'package:finance_app/features/goals/domain/entities/goal.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'accounts for concurrent reserve changes and leaves cash balances intact',
    () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(db.close);
      final repo = GoalRepositoryImpl(db);
      final accountId = await db
          .into(db.accounts)
          .insert(
            AccountsCompanion.insert(
              name: 'Carteira',
              type: 'cash',
              currentBalanceCents: const Value(15000),
            ),
          );
      final id = await repo.createGoal(
        Goal(
          name: 'Viagem',
          targetCents: 4000,
          savedCents: 1001,
          dueDate: DateTime(2027, 1, 20),
          accountId: accountId,
        ),
      );

      await Future.wait([
        repo.adjustReserve(id, 3333),
        repo.adjustReserve(id, 101),
      ]);
      final reached = (await repo.watchGoal(id).first)!;
      expect(reached.savedCents, 4435);
      expect(reached.isReached, isTrue);
      expect(reached.remainingCents, 0);

      await repo.updateGoal(
        Goal(
          id: id,
          name: 'Férias',
          targetCents: 5000,
          dueDate: DateTime(2027, 2, 20),
        ),
      );
      await repo.adjustReserve(id, -5);
      await expectLater(repo.adjustReserve(id, -4431), throwsStateError);
      final edited = (await repo.watchGoals().first).single;
      expect(edited.savedCents, 4430);
      expect(edited.remainingCents, 570);
      expect(edited.progressPercent, 88);
      expect(edited.accountId, isNull);
      expect(edited.isOverdue(DateTime(2027, 2, 20, 22)), isFalse);
      expect(edited.isOverdue(DateTime(2027, 2, 21)), isTrue);
      expect(
        (await db.select(db.accounts).getSingle()).currentBalanceCents,
        15000,
      );
      expect(await db.select(db.transactions).get(), isEmpty);

      await repo.deleteGoal(id);
      expect(await repo.watchGoal(id).first, isNull);
    },
  );

  test('rejects invalid targets and archived accounts on new links', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    final repo = GoalRepositoryImpl(db);
    final accountId = await db
        .into(db.accounts)
        .insert(
          AccountsCompanion.insert(
            name: 'Arquivada',
            type: 'cash',
            isActive: const Value(false),
          ),
        );
    final date = DateTime(2027);
    await expectLater(
      Future.sync(
        () => repo.createGoal(
          Goal(name: 'Viagem', targetCents: 0, dueDate: date),
        ),
      ),
      throwsStateError,
    );
    await expectLater(
      repo.createGoal(
        Goal(
          name: 'Viagem',
          targetCents: 10000,
          dueDate: date,
          accountId: accountId,
        ),
      ),
      throwsStateError,
    );
    expect(await repo.watchGoals().first, isEmpty);
  });
}
