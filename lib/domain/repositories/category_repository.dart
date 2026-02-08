import 'package:dartz/dartz.dart';

import '../../core/error/failures.dart';
import '../entities/category.dart';

/// Abstract repository interface for category operations.
abstract class CategoryRepository {
  /// Get all categories
  Future<Either<Failure, List<Category>>> getAllCategories();

  /// Get a single category by ID
  Future<Either<Failure, Category>> getCategoryById(String id);

  /// Create a new category
  Future<Either<Failure, Category>> createCategory(Category category);

  /// Update an existing category
  Future<Either<Failure, Category>> updateCategory(Category category);

  /// Delete a category by ID
  Future<Either<Failure, void>> deleteCategory(String id);
}
