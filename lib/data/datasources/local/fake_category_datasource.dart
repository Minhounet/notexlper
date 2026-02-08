import 'package:flutter/material.dart';

import '../../../domain/entities/category.dart';

/// Fake data source for categories (development and testing).
/// Stores data in memory.
class FakeCategoryDataSource {
  final Map<String, Category> _categories = {};
  final Duration delay;

  FakeCategoryDataSource({this.delay = const Duration(milliseconds: 100)}) {
    _seedData();
  }

  void _seedData() {
    final seeds = [
      Category(
        id: 'cat-1',
        name: 'Urgent',
        colorValue: Colors.red.value,
      ),
      Category(
        id: 'cat-2',
        name: 'Shopping',
        colorValue: Colors.green.value,
      ),
      Category(
        id: 'cat-3',
        name: 'Work',
        colorValue: Colors.blue.value,
      ),
    ];
    for (final cat in seeds) {
      _categories[cat.id] = cat;
    }
  }

  Future<void> _simulateDelay() async {
    if (delay > Duration.zero) {
      await Future.delayed(delay);
    }
  }

  Future<List<Category>> getAllCategories() async {
    await _simulateDelay();
    return _categories.values.toList();
  }

  Future<Category?> getCategoryById(String id) async {
    await _simulateDelay();
    return _categories[id];
  }

  Future<Category> createCategory(Category category) async {
    await _simulateDelay();
    _categories[category.id] = category;
    return category;
  }

  Future<Category> updateCategory(Category category) async {
    await _simulateDelay();
    _categories[category.id] = category;
    return category;
  }

  Future<void> deleteCategory(String id) async {
    await _simulateDelay();
    _categories.remove(id);
  }

  /// Clears all data - useful for testing
  void clear() {
    _categories.clear();
  }
}
