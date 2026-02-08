import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/datasources/local/fake_category_datasource.dart';
import '../../data/repositories/category_repository_impl.dart';
import '../../domain/entities/category.dart';
import '../../domain/repositories/category_repository.dart';

/// Provides the category data source instance (singleton)
final categoryDataSourceProvider = Provider<FakeCategoryDataSource>((ref) {
  return FakeCategoryDataSource();
});

/// Provides the category repository instance
final categoryRepositoryProvider = Provider<CategoryRepository>((ref) {
  return CategoryRepositoryImpl(
    dataSource: ref.watch(categoryDataSourceProvider),
  );
});

/// State notifier for managing the list of categories
class CategoryListNotifier extends StateNotifier<AsyncValue<List<Category>>> {
  final CategoryRepository _repository;

  CategoryListNotifier(this._repository) : super(const AsyncValue.loading()) {
    loadCategories();
  }

  Future<void> loadCategories() async {
    state = const AsyncValue.loading();
    final result = await _repository.getAllCategories();
    result.fold(
      (failure) => state = AsyncValue.error(failure.message, StackTrace.current),
      (categories) => state = AsyncValue.data(categories),
    );
  }

  Future<void> createCategory(Category category) async {
    await _repository.createCategory(category);
    await loadCategories();
  }

  Future<void> updateCategory(Category category) async {
    await _repository.updateCategory(category);
    await loadCategories();
  }

  Future<void> deleteCategory(String id) async {
    await _repository.deleteCategory(id);
    await loadCategories();
  }
}

/// Provider for the category list
final categoryListProvider =
    StateNotifierProvider<CategoryListNotifier, AsyncValue<List<Category>>>((ref) {
  final repository = ref.watch(categoryRepositoryProvider);
  return CategoryListNotifier(repository);
});
