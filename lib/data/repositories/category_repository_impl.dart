import 'package:dartz/dartz.dart';

import '../../core/error/failures.dart';
import '../../domain/entities/category.dart';
import '../../domain/repositories/category_repository.dart';
import '../datasources/local/fake_category_datasource.dart';

/// Implementation of CategoryRepository using the fake data source.
class CategoryRepositoryImpl implements CategoryRepository {
  final FakeCategoryDataSource dataSource;

  CategoryRepositoryImpl({required this.dataSource});

  @override
  Future<Either<Failure, List<Category>>> getAllCategories() async {
    try {
      final categories = await dataSource.getAllCategories();
      return Right(categories);
    } catch (e) {
      return const Left(CacheFailure('Failed to fetch categories'));
    }
  }

  @override
  Future<Either<Failure, Category>> getCategoryById(String id) async {
    try {
      final category = await dataSource.getCategoryById(id);
      if (category == null) {
        return const Left(NotFoundFailure('Category not found'));
      }
      return Right(category);
    } catch (e) {
      return const Left(CacheFailure('Failed to fetch category'));
    }
  }

  @override
  Future<Either<Failure, Category>> createCategory(Category category) async {
    try {
      final created = await dataSource.createCategory(category);
      return Right(created);
    } catch (e) {
      return const Left(CacheFailure('Failed to create category'));
    }
  }

  @override
  Future<Either<Failure, Category>> updateCategory(Category category) async {
    try {
      final updated = await dataSource.updateCategory(category);
      return Right(updated);
    } catch (e) {
      return const Left(CacheFailure('Failed to update category'));
    }
  }

  @override
  Future<Either<Failure, void>> deleteCategory(String id) async {
    try {
      await dataSource.deleteCategory(id);
      return const Right(null);
    } catch (e) {
      return const Left(CacheFailure('Failed to delete category'));
    }
  }
}
