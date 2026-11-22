import 'package:drift/drift.dart';

import 'transactions_table.dart';

@DataClassName('InvestmentRow')
class Investments extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 80)();
  TextColumn get institution => text().withLength(min: 0, max: 80)();
  TextColumn get kind => text().withLength(min: 1, max: 50)();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
}

@DataClassName('InvestmentMovementRow')
@TableIndex(name: 'investment_movements_by_position', columns: {#investmentId})
class InvestmentMovements extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get investmentId => integer().references(Investments, #id)();
  TextColumn get kind => text()();
  DateTimeColumn get date => dateTime()();
  IntColumn get amountCents => integer()();
  IntColumn get cashCents => integer().withDefault(const Constant(0))();
  IntColumn get valueCents => integer()();
  IntColumn get redeemableCents => integer()();
  IntColumn get transactionId =>
      integer().nullable().unique().references(Transactions, #id)();
}
