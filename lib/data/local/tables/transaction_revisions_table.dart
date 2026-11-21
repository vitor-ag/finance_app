import 'package:drift/drift.dart';

import 'transactions_table.dart';

@DataClassName('TransactionRevisionRow')
class TransactionRevisions extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get transactionId => integer().references(Transactions, #id)();
  TextColumn get action => text()();
  DateTimeColumn get recordedAt => dateTime().withDefault(currentDateAndTime)();
  TextColumn get snapshot => text()();
}
