import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:finance_app/data/local/database.dart';
import 'package:finance_app/features/categories/data/repositories/category_repository_impl.dart';
import 'package:finance_app/features/categories/domain/entities/category.dart';

void main() {
  test('create and read a category', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    final repo = CategoryRepositoryImpl(db);

    final id = await repo.createCategory(
      const Category(name: 'Alimentação', type: 'expense'),
    );

    final category = await repo.getCategoryById(id);

    expect(category, isNotNull);
    expect(category!.name, 'Alimentação');
    expect(category.type, 'expense');

    await db.close();
  });
}