import 'package:drift/drift.dart';

@DataClassName('CategoryRow')
class Categories extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 60)();
  TextColumn get type => text()();
  IntColumn get parentId =>
      integer().nullable().references(Categories, #id)();
  TextColumn get color => text().nullable()();
  TextColumn get icon => text().nullable()();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
}