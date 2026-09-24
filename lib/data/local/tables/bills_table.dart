import 'package:drift/drift.dart';
import 'accounts_table.dart';
import 'categories_table.dart';

@DataClassName('BillRow')
class Bills extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 80)();
  IntColumn get categoryId =>
      integer().nullable().references(Categories, #id)();
  RealColumn get amount => real()();
  DateTimeColumn get dueDate => dateTime()();

  // 'fixed', 'recurring', 'eventual'
  TextColumn get billType => text()();

  // 'pending', 'paid', 'cancelled'
  // 'overdue' is never stored — it's computed at read time from dueDate.
  TextColumn get status => text().withDefault(const Constant('pending'))();

  IntColumn get paymentAccountId =>
      integer().nullable().references(Accounts, #id)();

  // Links to the Transaction created when this bill was marked as paid.
  IntColumn get paidTransactionId => integer().nullable()();

  TextColumn get notes => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}