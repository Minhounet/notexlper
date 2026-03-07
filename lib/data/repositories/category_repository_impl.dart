import 'package:dartz/dartz.dart';

import '../../core/error/failures.dart';
import '../../core/logging/app_logger.dart';
import '../../domain/entities/category.dart';
import '../../domain/repositories/category_repository.dart';
import '../datasources/category_datasource.dart';

/// Implementation of [CategoryRepository].
/// Accepts any [CategoryDataSource] — use [FakeCategoryDataSource] in dev,
/// a Supabase implementation in prod.
class CategoryRepositoryImpl implements CategoryRepository {
  final CategoryDataSource dataSource;

  CategoryRepositoryImpl({required this.dataSource});

  @override
  Future<Either<Failure, List<Category>>> getAllCategories() async {
    try {
      final categories = await dataSource.getAllCategories();
      return Right(categories);
    } catch (e, s) {
      AppLogger.instance.log('getAllCategories failed', error: e, stackTrace: s);
      return Left(CacheFailure('Failed to fetch categories: $e'));
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
    } catch (e, s) {
      AppLogger.instance.log('getCategoryById($id) failed', error: e, stackTrace: s);
      return Left(CacheFailure('Failed to fetch category: $e'));
    }
  }

  @override
  Future<Either<Failure, Category>> createCategory(Category category) async {
    try {
      final created = await dataSource.createCategory(category);
      return Right(created);
    } catch (e, s) {
      AppLogger.instance.log('createCategory failed', error: e, stackTrace: s);
      return Left(CacheFailure('Failed to create category: $e'));
    }
  }

  @override
  Future<Either<Failure, Category>> updateCategory(Category category) async {
    try {
      final updated = await dataSource.updateCategory(category);
      return Right(updated);
    } catch (e, s) {
      AppLogger.instance.log('updateCategory failed', error: e, stackTrace: s);
      return Left(CacheFailure('Failed to update category: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> deleteCategory(String id) async {
    try {
      await dataSource.deleteCategory(id);
      return const Right(null);
    } catch (e, s) {
      AppLogger.instance.log('deleteCategory($id) failed', error: e, stackTrace: s);
      return Left(CacheFailure('Failed to delete category: $e'));
    }
  }
}
