import 'package:drift/drift.dart';
import 'accounts_table.dart';

class Categories extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 60)();
  TextColumn get type => text()(); // 'income' or 'expense'
  IntColumn get parentId =>
      integer().nullable().references(Categories, #id)(); // subcategory
  TextColumn get color => text().nullable()();
  TextColumn get icon => text().nullable()();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
}