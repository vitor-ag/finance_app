import 'package:drift/drift.dart';

import '../../../../core/calendar.dart';
import '../../../../core/money.dart';
import '../../../../data/local/database.dart';
import '../../domain/entities/goal.dart';
import '../../domain/repositories/goal_repository.dart';

class GoalRepositoryImpl implements GoalRepository {
  GoalRepositoryImpl(this.db);

  final AppDatabase db;

  Goal _mapRow(GoalRow row) => Goal(
    id: row.id,
    name: row.name,
    targetCents: row.targetCents,
    savedCents: row.savedCents,
    dueDate: row.dueDate,
    accountId: row.accountId,
    icon: row.icon,
  );

  SimpleSelectStatement<$GoalsTable, GoalRow> _byId(int id) =>
      db.select(db.goals)..where((table) => table.id.equals(id));

  @override
  Stream<List<Goal>> watchGoals() =>
      (db.select(db.goals)..orderBy([
            (table) => OrderingTerm.asc(table.dueDate),
            (table) => OrderingTerm.asc(table.id),
          ]))
          .watch()
          .map((rows) => rows.map(_mapRow).toList());

  @override
  Stream<Goal?> watchGoal(int id) =>
      _byId(id)
          .watchSingleOrNull()
          .map((row) => row == null ? null : _mapRow(row));

  @override
  Future<int> createGoal(Goal goal) {
    _validateDetails(goal);
    _validateReserve(goal.savedCents);
    return db.transaction(() async {
      await _validateLinkedAccount(goal.accountId);
      final id = await db
          .into(db.goals)
          .insert(
            GoalsCompanion.insert(
              name: goal.name.trim(),
              targetCents: goal.targetCents,
              dueDate: Value(
                goal.dueDate == null ? null : calendarDate(goal.dueDate!),
              ),
              savedCents: Value(goal.savedCents),
              accountId: Value(goal.accountId),
              icon: Value(goal.icon),
            ),
          );
      if (goal.savedCents > 0) await _recordMovement(id, goal.savedCents);
      return id;
    });
  }

  @override
  Future<void> updateGoal(Goal goal) {
    _validateDetails(goal);
    final id = goal.id!;
    return db.transaction(() async {
      final previous = await _requireGoal(id);
      if (previous.accountId != goal.accountId) {
        await _validateLinkedAccount(goal.accountId);
      }
      await (db.update(db.goals)..where((table) => table.id.equals(id))).write(
        GoalsCompanion(
          name: Value(goal.name.trim()),
          targetCents: Value(goal.targetCents),
          dueDate: Value(
            goal.dueDate == null ? null : calendarDate(goal.dueDate!),
          ),
          accountId: Value(goal.accountId),
          icon: Value(goal.icon),
        ),
      );
    });
  }

  @override
  Future<void> adjustReserve(int id, int deltaCents) {
    if (deltaCents == 0 ||
        deltaCents < -maxMoneyCents ||
        deltaCents > maxMoneyCents) {
      throw StateError('Informe um valor válido para ajustar a reserva.');
    }
    return db.transaction(() async {
      final current = await _requireGoal(id);
      final savedCents = current.savedCents + deltaCents;
      _validateReserve(savedCents);
      await (db.update(db.goals)..where((table) => table.id.equals(id))).write(
        GoalsCompanion(savedCents: Value(savedCents)),
      );
      await _recordMovement(id, deltaCents);
    });
  }

  Future<void> _recordMovement(int id, int delta) => db
      .into(db.goalMovements)
      .insert(GoalMovementsCompanion.insert(goalId: id, deltaCents: delta));

  @override
  Future<void> deleteGoal(int id) =>
      (db.delete(db.goals)..where((table) => table.id.equals(id))).go();

  Future<GoalRow> _requireGoal(int id) async {
    final current = await _byId(id).getSingleOrNull();
    if (current == null) {
      throw StateError('Esta meta não está mais disponível.');
    }
    return current;
  }

  void _validateDetails(Goal goal) {
    final length = goal.name.trim().length;
    if (length < 1 || length > 80) {
      throw StateError('Informe um nome com até 80 caracteres.');
    }
    validatePositiveCents(goal.targetCents);
  }

  void _validateReserve(int cents) {
    if (cents < 0) {
      throw StateError('O valor retirado supera a reserva da meta.');
    }
    validateBalanceCents(cents);
  }

  Future<void> _validateLinkedAccount(int? id) async {
    if (id == null) return;
    final account =
        await (db.select(db.accounts)..where(
              (table) => table.id.equals(id) & table.isActive.equals(true),
            ))
            .getSingleOrNull();
    if (account == null) throw StateError('Selecione uma conta ativa.');
  }
}
