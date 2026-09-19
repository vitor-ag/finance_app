import '../entities/category.dart';

abstract class CategoryRepository {
  Stream<List<Category>> watchAllCategories({String? type});
  Future<Category?> getCategoryById(int id);
  Future<int> createCategory(Category category);
  Future<void> updateCategory(Category category);
  Future<void> archiveCategory(int id);
}