import 'package:drift/drift.dart';

import 'goals_table.dart';

@DataClassName('GoalMovementRow')
class GoalMovements extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get goalId =>
      integer().references(Goals, #id, onDelete: KeyAction.cascade)();
  IntColumn get deltaCents => integer()();
  DateTimeColumn get date => dateTime().withDefault(currentDateAndTime)();
}
