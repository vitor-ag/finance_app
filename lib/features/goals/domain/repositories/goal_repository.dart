import '../entities/goal.dart';

abstract class GoalRepository {
  Future<List<Goal>> readGoals();
  Stream<List<Goal>> watchGoals();
  Stream<Goal?> watchGoal(int id);
  Future<int> createGoal(Goal goal);
  Future<void> updateGoal(Goal goal);
  Future<void> adjustReserve(int id, int deltaCents);
  Future<void> deleteGoal(int id);
}
