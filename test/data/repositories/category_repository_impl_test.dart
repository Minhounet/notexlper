import 'package:flutter_test/flutter_test.dart';
import 'package:notexlper/data/datasources/local/fake_category_datasource.dart';
import 'package:notexlper/data/repositories/category_repository_impl.dart';
import 'package:notexlper/domain/entities/category.dart';

void main() {
  late FakeCategoryDataSource dataSource;
  late CategoryRepositoryImpl repository;

  setUp(() {
    dataSource = FakeCategoryDataSource();
    dataSource.clear();
    repository = CategoryRepositoryImpl(dataSource: dataSource);
  });

  const testCategory = Category(
    id: 'cat-test-1',
    name: 'Test Category',
    colorValue: 0xFF2196F3,
  );

  group('CategoryRepositoryImpl', () {
    group('createCategory', () {
      test('should create a category and return it', () async {
        final result = await repository.createCategory(testCategory);

        expect(result.isRight(), true);
        result.fold(
          (failure) => fail('Should not return failure'),
          (category) {
            expect(category.id, testCategory.id);
            expect(category.name, testCategory.name);
            expect(category.colorValue, testCategory.colorValue);
          },
        );
      });
    });

    group('getAllCategories', () {
      test('should return empty list when no categories exist', () async {
        final result = await repository.getAllCategories();

        expect(result.isRight(), true);
        result.fold(
          (failure) => fail('Should not return failure'),
          (categories) => expect(categories, isEmpty),
        );
      });

      test('should return all created categories', () async {
        await repository.createCategory(testCategory);

        final result = await repository.getAllCategories();

        expect(result.isRight(), true);
        result.fold(
          (failure) => fail('Should not return failure'),
          (categories) => expect(categories.length, 1),
        );
      });
    });

    group('getCategoryById', () {
      test('should return category when it exists', () async {
        await repository.createCategory(testCategory);

        final result = await repository.getCategoryById(testCategory.id);

        expect(result.isRight(), true);
        result.fold(
          (failure) => fail('Should not return failure'),
          (category) => expect(category.id, testCategory.id),
        );
      });

      test('should return NotFoundFailure when category does not exist', () async {
        final result = await repository.getCategoryById('non-existent');

        expect(result.isLeft(), true);
      });
    });

    group('updateCategory', () {
      test('should update a category', () async {
        await repository.createCategory(testCategory);

        final updated = testCategory.copyWith(name: 'Updated');
        final result = await repository.updateCategory(updated);

        expect(result.isRight(), true);
        result.fold(
          (failure) => fail('Should not return failure'),
          (category) => expect(category.name, 'Updated'),
        );
      });
    });

    group('deleteCategory', () {
      test('should delete existing category', () async {
        await repository.createCategory(testCategory);

        final deleteResult = await repository.deleteCategory(testCategory.id);
        expect(deleteResult.isRight(), true);

        final getResult = await repository.getCategoryById(testCategory.id);
        expect(getResult.isLeft(), true);
      });
    });
  });
}
