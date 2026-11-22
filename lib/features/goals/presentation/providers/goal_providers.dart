import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/database_provider.dart';
import '../../../../data/local/database.dart';
import '../../data/repositories/goal_repository_impl.dart';
import '../../domain/entities/goal.dart';
import '../../domain/goal_plan.dart';
import '../../../forecast/presentation/cash_forecast_provider.dart';
import '../../domain/repositories/goal_repository.dart';

final goalRepositoryProvider = Provider<GoalRepository>(
  (ref) => GoalRepositoryImpl(ref.watch(databaseProvider)),
);

final allGoalsProvider = StreamProvider.autoDispose<List<Goal>>(
  (ref) => ref.watch(goalRepositoryProvider).watchGoals(),
);

final goalByIdProvider = StreamProvider.autoDispose.family<Goal?, int>(
  (ref, id) => ref.watch(goalRepositoryProvider).watchGoal(id),
);

final goalMovementsProvider = StreamProvider.autoDispose
    .family<List<GoalMovementRow>, int>((ref, id) {
      final db = ref.watch(databaseProvider);
      return (db.select(db.goalMovements)
            ..where((row) => row.goalId.equals(id))
            ..orderBy([(row) => OrderingTerm.desc(row.id)]))
          .watch();
    });

final goalPlansProvider = StreamProvider.autoDispose<List<GoalPlan>>((ref) {
  final db = ref.watch(databaseProvider);
  final today = ref.watch(cashForecastDateProvider);
  final repository = ref.watch(goalRepositoryProvider);
  return db
      .customSelect('SELECT 1', readsFrom: {db.goals, db.goalMovements})
      .watch()
      .asyncMap(
        (_) => db.transaction(() async {
          final goals = await repository.readGoals();
          final month = DateTime(today.year, today.month);
          final moves =
              await (db.select(db.goalMovements)..where(
                    (row) =>
                        row.date.isBiggerOrEqualValue(month) &
                        row.date.isSmallerThanValue(
                          DateTime(today.year, today.month + 1),
                        ),
                  ))
                  .get();
          final saved = <int, BigInt>{};
          for (final move in moves) {
            saved.update(
              move.goalId,
              (value) => value + BigInt.from(move.deltaCents),
              ifAbsent: () => BigInt.from(move.deltaCents),
            );
          }
          return [
            for (final goal in goals)
              GoalPlan(
                goal,
                today,
                savedThisMonth: saved[goal.id] ?? BigInt.zero,
              ),
          ];
        }),
      );
});
