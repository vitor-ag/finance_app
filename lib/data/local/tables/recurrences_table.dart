import 'package:drift/drift.dart';

import 'accounts_table.dart';
import 'categories_table.dart';

@DataClassName('RecurrenceRow')
class Recurrences extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 80)();

  // 'income', 'expense', 'transfer'
  TextColumn get type => text()();

  IntColumn get amountCents => integer()();

  IntColumn get accountId => integer().references(Accounts, #id)();
  IntColumn get destinationAccountId =>
      integer().nullable().references(Accounts, #id)();
  IntColumn get categoryId =>
      integer().nullable().references(Categories, #id)();

  TextColumn get description => text().nullable()();

  // 'monthly', 'weekly', 'yearly'
  TextColumn get frequency => text()();

  // used for monthly/yearly (1-31, clamped to each month's length)
  IntColumn get dayOfMonth => integer().nullable()();

  // used for weekly (1 = Monday ... 7 = Sunday)
  IntColumn get weekday => integer().nullable()();

  DateTimeColumn get startDate => dateTime()();
  DateTimeColumn get endDate => dateTime().nullable()();
  IntColumn get maxOccurrences => integer().nullable()();
  IntColumn get generatedCount => integer().withDefault(const Constant(0))();
  DateTimeColumn get nextOccurrenceDate => dateTime()();

  // 'active', 'paused', 'finished', 'cancelled'
  TextColumn get status => text().withDefault(const Constant('active'))();

  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}
