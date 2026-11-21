import 'package:drift/drift.dart';

import 'accounts_table.dart';
import 'categories_table.dart';
import 'transactions_table.dart';

@DataClassName('CreditCardRow')
class CreditCards extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 80)();
  IntColumn get limitCents => integer()();
  IntColumn get closingDay => integer()();
  IntColumn get dueDay => integer()();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
}

@DataClassName('CardPurchaseRow')
class CardPurchases extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get cardId => integer().references(CreditCards, #id)();
  TextColumn get description => text().withLength(min: 1, max: 100)();
  IntColumn get amountCents => integer()();
  DateTimeColumn get purchaseDate => dateTime()();
  IntColumn get categoryId =>
      integer().nullable().references(Categories, #id)();
  IntColumn get installmentCount => integer()();
}

@DataClassName('CardPaymentRow')
class CardPayments extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get cardId => integer().references(CreditCards, #id)();
  DateTimeColumn get closingDate => dateTime()();
  IntColumn get accountId => integer().references(Accounts, #id)();
  IntColumn get transactionId => integer().references(Transactions, #id)();
  IntColumn get amountCents => integer()();
  DateTimeColumn get paidAt => dateTime()();
}

@DataClassName('CardInstallmentRow')
class CardInstallments extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get purchaseId => integer().references(CardPurchases, #id)();
  IntColumn get number => integer()();
  IntColumn get amountCents => integer()();
  DateTimeColumn get closingDate => dateTime()();
  DateTimeColumn get dueDate => dateTime()();
  IntColumn get paymentId =>
      integer().nullable().references(CardPayments, #id)();
}
