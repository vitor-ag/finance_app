import 'package:drift/drift.dart';
import 'accounts_table.dart';
import 'categories_table.dart';

@DataClassName('TransactionRow')
class Transactions extends Table {
  IntColumn get id => integer().autoIncrement()();

  // 'income', 'expense', 'transfer'
  TextColumn get type => text()();

  RealColumn get amount => real()();

  DateTimeColumn get date => dateTime()();

  IntColumn get accountId =>
      integer().references(Accounts, #id)();

  // used only for transfers: destination account
  IntColumn get destinationAccountId =>
      integer().nullable().references(Accounts, #id)();

  IntColumn get categoryId =>
      integer().nullable().references(Categories, #id)();

  TextColumn get description => text().nullable()();

  // 'pending', 'paid', 'cancelled'
  TextColumn get status => text().withDefault(const Constant('paid'))();

  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  // soft delete
  DateTimeColumn get deletedAt => dateTime().nullable()();
}