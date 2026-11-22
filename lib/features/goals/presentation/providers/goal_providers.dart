import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/database_provider.dart';
import '../../../../data/local/database.dart';
import '../../data/repositories/goal_repository_impl.dart';
import '../../domain/entities/goal.dart';
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
