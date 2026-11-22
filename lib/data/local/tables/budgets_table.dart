import 'package:drift/drift.dart';

import 'categories_table.dart';

@DataClassName('BudgetRow')
class Budgets extends Table {
  IntColumn get categoryId => integer().references(Categories, #id)();
  DateTimeColumn get month => dateTime()();
  IntColumn get limitCents =>
      integer().customConstraint('NOT NULL CHECK (limit_cents > 0)')();
  BoolColumn get carryOver => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {categoryId, month};
}
