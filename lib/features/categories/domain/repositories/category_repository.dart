import '../entities/category.dart';

abstract class CategoryRepository {
  Future<void> reorderCategories(String type, List<int> ids);
  Stream<List<Category>> watchAllCategories({String? type});
  Future<Category?> getCategoryById(int id);
  Future<int> createCategory(Category category);
  Future<void> updateCategory(Category category);
  Future<void> archiveCategory(int id);
}
