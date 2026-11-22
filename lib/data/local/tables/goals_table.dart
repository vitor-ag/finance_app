import 'package:drift/drift.dart';

import 'accounts_table.dart';

@DataClassName('GoalRow')
class Goals extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 80)();
  IntColumn get targetCents => integer()();
  IntColumn get savedCents => integer().withDefault(const Constant(0))();
  DateTimeColumn get dueDate => dateTime().nullable()();
  IntColumn get accountId => integer().nullable().references(Accounts, #id)();
  TextColumn get icon => text().nullable()();
}
