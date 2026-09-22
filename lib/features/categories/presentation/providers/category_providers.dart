import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../../core/providers/database_provider.dart';
import '../../data/repositories/category_repository_impl.dart';
import '../../domain/entities/category.dart';
import '../../domain/repositories/category_repository.dart';

part 'category_providers.g.dart';

@Riverpod(keepAlive: true)
CategoryRepository categoryRepository(CategoryRepositoryRef ref) {
  final db = ref.watch(databaseProvider);
  return CategoryRepositoryImpl(db);
}

@riverpod
Stream<List<Category>> allCategories(AllCategoriesRef ref, {String? type}) {
  final repo = ref.watch(categoryRepositoryProvider);
  return repo.watchAllCategories(type: type);
}