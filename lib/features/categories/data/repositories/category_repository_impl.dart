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
    final row = await (db.select(
      db.categories,
    )..where((tbl) => tbl.id.equals(id))).getSingleOrNull();
    return row == null ? null : _mapRow(row);
  }

  @override
  Future<int> createCategory(Category category) {
    return db.transaction(() async {
      await _validateParent(category);
      return db
          .into(db.categories)
          .insert(
            CategoriesCompanion.insert(
              name: category.name,
              type: category.type,
              parentId: Value(category.parentId),
              color: Value(category.color),
              icon: Value(category.icon),
            ),
          );
    });
  }

  @override
  Future<void> updateCategory(Category category) {
    return db.transaction(() async {
      final existing = await getCategoryById(category.id!);
      if (existing == null) return;
      if (category.type != existing.type) {
        throw StateError('O tipo da categoria é definido no cadastro.');
      }
      if (category.parentId != existing.parentId) {
        await _validateParent(category);
      }
      await (db.update(
        db.categories,
      )..where((tbl) => tbl.id.equals(category.id!))).write(
        CategoriesCompanion(
          name: Value(category.name),
          parentId: Value(category.parentId),
          color: Value(category.color),
          icon: Value(category.icon),
        ),
      );
    });
  }

  @override
  Future<void> archiveCategory(int id) {
    return db.transaction(() async {
      if (await _hasChildren(id, activeOnly: true)) {
        throw StateError('Arquive as subcategorias ativas primeiro.');
      }
      await (db.update(db.categories)..where((tbl) => tbl.id.equals(id))).write(
        const CategoriesCompanion(isActive: Value(false)),
      );
    });
  }

  Future<void> _validateParent(Category category) async {
    final parentId = category.parentId;
    if (parentId == null) return;
    final parent = await getCategoryById(parentId);
    if (parentId == category.id ||
        parent == null ||
        !parent.isActive ||
        parent.type != category.type ||
        parent.parentId != null) {
      throw StateError(
        'Selecione uma categoria principal ativa do mesmo tipo.',
      );
    }
    final id = category.id;
    if (id != null && await _hasChildren(id)) {
      throw StateError(
        'Uma categoria com subcategorias deve permanecer principal.',
      );
    }
  }

  Future<bool> _hasChildren(int id, {bool activeOnly = false}) async {
    final query = db.select(db.categories)
      ..where(
        (tbl) =>
            tbl.parentId.equals(id) &
            (activeOnly ? tbl.isActive.equals(true) : const Constant(true)),
      )
      ..limit(1);
    return await query.getSingleOrNull() != null;
  }
}
