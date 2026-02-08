import 'package:flutter_test/flutter_test.dart';
import 'package:notexlper/domain/entities/category.dart';

void main() {
  group('Category', () {
    test('should create a category with required fields', () {
      const category = Category(
        id: 'cat-1',
        name: 'Work',
        colorValue: 0xFF2196F3,
      );

      expect(category.id, 'cat-1');
      expect(category.name, 'Work');
      expect(category.colorValue, 0xFF2196F3);
    });

    test('copyWith should create a copy with updated values', () {
      const category = Category(
        id: 'cat-1',
        name: 'Work',
        colorValue: 0xFF2196F3,
      );

      final updated = category.copyWith(name: 'Personal');

      expect(updated.name, 'Personal');
      expect(updated.id, 'cat-1');
      expect(updated.colorValue, 0xFF2196F3);
    });

    test('copyWith should update color', () {
      const category = Category(
        id: 'cat-1',
        name: 'Work',
        colorValue: 0xFF2196F3,
      );

      final updated = category.copyWith(colorValue: 0xFFF44336);

      expect(updated.colorValue, 0xFFF44336);
      expect(updated.name, 'Work');
    });

    test('two categories with same properties should be equal', () {
      const cat1 = Category(id: 'cat-1', name: 'Work', colorValue: 0xFF2196F3);
      const cat2 = Category(id: 'cat-1', name: 'Work', colorValue: 0xFF2196F3);

      expect(cat1, cat2);
    });

    test('two categories with different properties should not be equal', () {
      const cat1 = Category(id: 'cat-1', name: 'Work', colorValue: 0xFF2196F3);
      const cat2 = Category(id: 'cat-2', name: 'Personal', colorValue: 0xFFF44336);

      expect(cat1, isNot(cat2));
    });
  });
}
