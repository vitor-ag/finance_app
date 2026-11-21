import 'package:drift/drift.dart';

@DataClassName('BillReminderSettingsRow')
class BillReminderSettings extends Table {
  IntColumn get id => integer()();
  BoolColumn get enabled => boolean()();
  IntColumn get daysBefore => integer()();
  IntColumn get minuteOfDay => integer()();
  DateTimeColumn get configuredAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}
