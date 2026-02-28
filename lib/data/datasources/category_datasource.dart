import '../../domain/entities/category.dart';

/// Abstract data source interface for categories.
///
/// In dev mode, use [FakeCategoryDataSource].
/// In prod, implement with Supabase.
abstract class CategoryDataSource {
  Future<List<Category>> getAllCategories();
  Future<Category?> getCategoryById(String id);
  Future<Category> createCategory(Category category);
  Future<Category> updateCategory(Category category);
  Future<void> deleteCategory(String id);
}
