import 'package:drift/drift.dart';
import '../../../../data/local/database.dart';
import '../../domain/entities/category.dart';
import '../../domain/repositories/category_repository.dart';

class CategoryRepositoryImpl implements CategoryRepository {
  final AppDatabase db;

  CategoryRepositoryImpl(this.db);

  Category _mapRow(CategoryRow row) {
    return Category(
      id: row.id,
      name: row.name,
      type: row.type,
      parentId: row.parentId,
      color: row.color,
      icon: row.icon,
      isActive: row.isActive,
    );
  }

  @override
  Stream<List<Category>> watchAllCategories({String? type}) {
    final query = db.select(db.categories);
    if (type != null) {
      query.where((tbl) => tbl.type.equals(type));
    }
    return query.watch().map((rows) => rows.map(_mapRow).toList());
  }

  @override
  Future<Category?> getCategoryById(int id) async {
    final row = await (db.select(db.categories)
          ..where((tbl) => tbl.id.equals(id)))
        .getSingleOrNull();
    return row == null ? null : _mapRow(row);
  }

  @override
  Future<int> createCategory(Category category) {
    return db.into(db.categories).insert(
          CategoriesCompanion.insert(
            name: category.name,
            type: category.type,
            parentId: Value(category.parentId),
            color: Value(category.color),
            icon: Value(category.icon),
          ),
        );
  }

  @override
  Future<void> updateCategory(Category category) {
    return (db.update(db.categories)
          ..where((tbl) => tbl.id.equals(category.id!)))
        .write(
      CategoriesCompanion(
        name: Value(category.name),
        type: Value(category.type),
        parentId: Value(category.parentId),
        color: Value(category.color),
        icon: Value(category.icon),
      ),
    );
  }

  @override
  Future<void> archiveCategory(int id) {
    return (db.update(db.categories)..where((tbl) => tbl.id.equals(id)))
        .write(const CategoriesCompanion(isActive: Value(false)));
  }
}