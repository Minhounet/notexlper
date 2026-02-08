import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notexlper/data/datasources/local/fake_category_datasource.dart';
import 'package:notexlper/domain/entities/category.dart';
import 'package:notexlper/presentation/pages/category_admin_page.dart';
import 'package:notexlper/presentation/providers/category_providers.dart';

void main() {
  late FakeCategoryDataSource dataSource;

  setUp(() {
    dataSource = FakeCategoryDataSource(delay: Duration.zero);
    dataSource.clear();
  });

  Widget createCategoryAdminPage() {
    return ProviderScope(
      overrides: [
        categoryDataSourceProvider.overrideWithValue(dataSource),
      ],
      child: const MaterialApp(home: CategoryAdminPage()),
    );
  }

  group('CategoryAdminPage', () {
    testWidgets('should show empty state when no categories exist',
        (tester) async {
      await tester.pumpWidget(createCategoryAdminPage());
      await tester.pumpAndSettle();

      expect(find.text('No categories yet'), findsOneWidget);
      expect(find.text('Tap + to create your first category'), findsOneWidget);
    });

    testWidgets('should display existing categories', (tester) async {
      await dataSource.createCategory(const Category(
        id: 'cat-1',
        name: 'Work',
        colorValue: 0xFF2196F3,
      ));

      await tester.pumpWidget(createCategoryAdminPage());
      await tester.pumpAndSettle();

      expect(find.text('Work'), findsOneWidget);
    });

    testWidgets('should display multiple categories', (tester) async {
      await dataSource.createCategory(const Category(
        id: 'cat-1',
        name: 'Work',
        colorValue: 0xFF2196F3,
      ));
      await dataSource.createCategory(const Category(
        id: 'cat-2',
        name: 'Personal',
        colorValue: 0xFFF44336,
      ));

      await tester.pumpWidget(createCategoryAdminPage());
      await tester.pumpAndSettle();

      expect(find.text('Work'), findsOneWidget);
      expect(find.text('Personal'), findsOneWidget);
    });

    testWidgets('should show FAB to create category', (tester) async {
      await tester.pumpWidget(createCategoryAdminPage());
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.add), findsOneWidget);
    });

    testWidgets('should show create dialog when FAB is tapped', (tester) async {
      await tester.pumpWidget(createCategoryAdminPage());
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();

      expect(find.text('New Category'), findsOneWidget);
      expect(find.text('Category name'), findsOneWidget);
      expect(find.text('Create'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
    });

    testWidgets('should create a category via dialog', (tester) async {
      await tester.pumpWidget(createCategoryAdminPage());
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'Shopping');
      await tester.tap(find.text('Create'));
      await tester.pumpAndSettle();

      expect(find.text('Shopping'), findsOneWidget);
    });

    testWidgets('should show delete confirmation dialog', (tester) async {
      await dataSource.createCategory(const Category(
        id: 'cat-1',
        name: 'To Delete',
        colorValue: 0xFF2196F3,
      ));

      await tester.pumpWidget(createCategoryAdminPage());
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.delete_outline));
      await tester.pumpAndSettle();

      expect(find.text('Delete category?'), findsOneWidget);
    });

    testWidgets('should delete category when confirmed', (tester) async {
      await dataSource.createCategory(const Category(
        id: 'cat-1',
        name: 'To Delete',
        colorValue: 0xFF2196F3,
      ));

      await tester.pumpWidget(createCategoryAdminPage());
      await tester.pumpAndSettle();

      expect(find.text('To Delete'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.delete_outline));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();

      expect(find.text('To Delete'), findsNothing);
      expect(find.text('No categories yet'), findsOneWidget);
    });

    testWidgets('should show edit dialog when edit button is tapped',
        (tester) async {
      await dataSource.createCategory(const Category(
        id: 'cat-1',
        name: 'Old Name',
        colorValue: 0xFF2196F3,
      ));

      await tester.pumpWidget(createCategoryAdminPage());
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.edit_outlined));
      await tester.pumpAndSettle();

      expect(find.text('Edit Category'), findsOneWidget);
      expect(find.text('Save'), findsOneWidget);
    });

    testWidgets('should show Manage Categories in app bar', (tester) async {
      await tester.pumpWidget(createCategoryAdminPage());
      await tester.pumpAndSettle();

      expect(find.text('Manage Categories'), findsOneWidget);
    });
  });
}
