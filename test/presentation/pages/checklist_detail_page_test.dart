import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notexlper/data/datasources/local/fake_category_datasource.dart';
import 'package:notexlper/data/datasources/local/fake_checklist_datasource.dart';
import 'package:notexlper/domain/entities/category.dart';
import 'package:notexlper/domain/entities/checklist_item.dart';
import 'package:notexlper/domain/entities/checklist_note.dart';
import 'package:notexlper/presentation/pages/checklist_detail_page.dart';
import 'package:notexlper/presentation/providers/category_providers.dart';
import 'package:notexlper/presentation/providers/checklist_providers.dart';

void main() {
  late FakeChecklistDataSource dataSource;
  late FakeCategoryDataSource categoryDataSource;
  final now = DateTime(2024, 6, 1);

  setUp(() {
    dataSource = FakeChecklistDataSource(delay: Duration.zero);
    dataSource.clear();
    categoryDataSource = FakeCategoryDataSource(delay: Duration.zero);
    categoryDataSource.clear();
  });

  Widget createDetailPage(ChecklistNote note) {
    return ProviderScope(
      overrides: [
        dataSourceProvider.overrideWithValue(dataSource),
        categoryDataSourceProvider.overrideWithValue(categoryDataSource),
      ],
      child: MaterialApp(home: ChecklistDetailPage(note: note)),
    );
  }

  Widget createDetailPageWithNavigation(ChecklistNote note) {
    return ProviderScope(
      overrides: [
        dataSourceProvider.overrideWithValue(dataSource),
        categoryDataSourceProvider.overrideWithValue(categoryDataSource),
      ],
      child: MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: ElevatedButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => ChecklistDetailPage(note: note),
                  ),
                );
              },
              child: const Text('Open'),
            ),
          ),
        ),
      ),
    );
  }

  group('ChecklistDetailPage', () {
    testWidgets('should display title field with existing title',
        (tester) async {
      final note = ChecklistNote(
        id: 'note-1',
        title: 'Shopping',
        items: const [
          ChecklistItem(id: 'i1', text: 'Apples', order: 0),
        ],
        createdAt: now,
        updatedAt: now,
      );
      await dataSource.createNote(note);

      await tester.pumpWidget(createDetailPage(note));
      await tester.pumpAndSettle();

      expect(find.text('Shopping'), findsWidgets);
    });

    testWidgets('should display checklist items', (tester) async {
      final note = ChecklistNote(
        id: 'note-1',
        title: 'Tasks',
        items: const [
          ChecklistItem(id: 'i1', text: 'Task A', order: 0),
          ChecklistItem(id: 'i2', text: 'Task B', order: 1),
        ],
        createdAt: now,
        updatedAt: now,
      );
      await dataSource.createNote(note);

      await tester.pumpWidget(createDetailPage(note));
      await tester.pumpAndSettle();

      expect(find.text('Task A'), findsOneWidget);
      expect(find.text('Task B'), findsOneWidget);
    });

    testWidgets('should display checkboxes for items', (tester) async {
      final note = ChecklistNote(
        id: 'note-1',
        title: 'Tasks',
        items: const [
          ChecklistItem(id: 'i1', text: 'Unchecked', isChecked: false, order: 0),
          ChecklistItem(id: 'i2', text: 'Checked', isChecked: true, order: 1),
        ],
        createdAt: now,
        updatedAt: now,
      );
      await dataSource.createNote(note);

      await tester.pumpWidget(createDetailPage(note));
      await tester.pumpAndSettle();

      final checkboxes = tester.widgetList<Checkbox>(find.byType(Checkbox)).toList();
      expect(checkboxes.length, 2);
      expect(checkboxes[0].value, false);
      expect(checkboxes[1].value, true);
    });

    testWidgets('should toggle item when checkbox is tapped', (tester) async {
      final note = ChecklistNote(
        id: 'note-1',
        title: 'Tasks',
        items: const [
          ChecklistItem(id: 'i1', text: 'Toggle me', isChecked: false, order: 0),
        ],
        createdAt: now,
        updatedAt: now,
      );
      await dataSource.createNote(note);

      await tester.pumpWidget(createDetailPage(note));
      await tester.pumpAndSettle();

      // Verify initially unchecked
      var checkbox = tester.widget<Checkbox>(find.byType(Checkbox));
      expect(checkbox.value, false);

      // Tap the checkbox
      await tester.tap(find.byType(Checkbox));
      await tester.pumpAndSettle();

      // Should now be checked
      checkbox = tester.widget<Checkbox>(find.byType(Checkbox));
      expect(checkbox.value, true);
    });

    testWidgets('should uncheck a checked item when tapped', (tester) async {
      final note = ChecklistNote(
        id: 'note-1',
        title: 'Tasks',
        items: const [
          ChecklistItem(id: 'i1', text: 'Uncheck me', isChecked: true, order: 0),
        ],
        createdAt: now,
        updatedAt: now,
      );
      await dataSource.createNote(note);

      await tester.pumpWidget(createDetailPage(note));
      await tester.pumpAndSettle();

      var checkbox = tester.widget<Checkbox>(find.byType(Checkbox));
      expect(checkbox.value, true);

      await tester.tap(find.byType(Checkbox));
      await tester.pumpAndSettle();

      checkbox = tester.widget<Checkbox>(find.byType(Checkbox));
      expect(checkbox.value, false);
    });

    testWidgets('should add new item when FAB is tapped', (tester) async {
      final note = ChecklistNote(
        id: 'note-1',
        title: 'Tasks',
        items: const [
          ChecklistItem(id: 'i1', text: 'Existing', order: 0),
        ],
        createdAt: now,
        updatedAt: now,
      );
      await dataSource.createNote(note);

      await tester.pumpWidget(createDetailPage(note));
      await tester.pumpAndSettle();

      expect(find.byType(Checkbox), findsOneWidget);

      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();

      expect(find.byType(Checkbox), findsNWidgets(2));
    });

    testWidgets('should remove item when delete button is tapped',
        (tester) async {
      final note = ChecklistNote(
        id: 'note-1',
        title: 'Tasks',
        items: const [
          ChecklistItem(id: 'i1', text: 'Keep', order: 0),
          ChecklistItem(id: 'i2', text: 'Remove', order: 1),
        ],
        createdAt: now,
        updatedAt: now,
      );
      await dataSource.createNote(note);

      await tester.pumpWidget(createDetailPage(note));
      await tester.pumpAndSettle();

      expect(find.byType(Checkbox), findsNWidgets(2));

      // Tap the second close button (for "Remove" item)
      final closeButtons = find.byIcon(Icons.close);
      await tester.tap(closeButtons.last);
      await tester.pumpAndSettle();

      expect(find.byType(Checkbox), findsOneWidget);
      expect(find.text('Remove'), findsNothing);
    });

    testWidgets('should show completion count in app bar', (tester) async {
      final note = ChecklistNote(
        id: 'note-1',
        title: 'Tasks',
        items: const [
          ChecklistItem(id: 'i1', text: 'Done', isChecked: true, order: 0),
          ChecklistItem(id: 'i2', text: 'Not done', isChecked: false, order: 1),
          ChecklistItem(id: 'i3', text: 'Also done', isChecked: true, order: 2),
        ],
        createdAt: now,
        updatedAt: now,
      );
      await dataSource.createNote(note);

      await tester.pumpWidget(createDetailPage(note));
      await tester.pumpAndSettle();

      expect(find.text('2/3'), findsOneWidget);
    });

    testWidgets('should show back button when pushed on navigation stack',
        (tester) async {
      final note = ChecklistNote(
        id: 'note-1',
        title: 'Tasks',
        items: const [
          ChecklistItem(id: 'i1', text: 'Item', order: 0),
        ],
        createdAt: now,
        updatedAt: now,
      );
      await dataSource.createNote(note);

      await tester.pumpWidget(createDetailPageWithNavigation(note));
      await tester.pumpAndSettle();

      // Navigate to the detail page
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      // AppBar should have a back button
      expect(find.byType(BackButton), findsOneWidget);
    });

    testWidgets('should update completion count when toggling items',
        (tester) async {
      final note = ChecklistNote(
        id: 'note-1',
        title: 'Tasks',
        items: const [
          ChecklistItem(id: 'i1', text: 'Task 1', isChecked: false, order: 0),
          ChecklistItem(id: 'i2', text: 'Task 2', isChecked: false, order: 1),
        ],
        createdAt: now,
        updatedAt: now,
      );
      await dataSource.createNote(note);

      await tester.pumpWidget(createDetailPage(note));
      await tester.pumpAndSettle();

      expect(find.text('0/2'), findsOneWidget);

      // Check the first item
      await tester.tap(find.byType(Checkbox).first);
      await tester.pumpAndSettle();

      expect(find.text('1/2'), findsOneWidget);
    });
  });

  group('Display mode menu', () {
    testWidgets('should show display mode menu button in app bar',
        (tester) async {
      final note = ChecklistNote(
        id: 'note-1',
        title: 'Tasks',
        items: const [
          ChecklistItem(id: 'i1', text: 'Item', order: 0),
        ],
        createdAt: now,
        updatedAt: now,
      );
      await dataSource.createNote(note);

      await tester.pumpWidget(createDetailPage(note));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.view_list), findsOneWidget);
    });

    testWidgets('should show menu options when display mode button is tapped',
        (tester) async {
      final note = ChecklistNote(
        id: 'note-1',
        title: 'Tasks',
        items: const [
          ChecklistItem(id: 'i1', text: 'Item', order: 0),
        ],
        createdAt: now,
        updatedAt: now,
      );
      await dataSource.createNote(note);

      await tester.pumpWidget(createDetailPage(note));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.view_list));
      await tester.pumpAndSettle();

      expect(find.text('Flat view'), findsOneWidget);
      expect(find.text('Group by category'), findsOneWidget);
      expect(find.text('Checked at bottom'), findsOneWidget);
    });
  });

  group('Checked at bottom mode', () {
    testWidgets('should move checked items to bottom in flat mode',
        (tester) async {
      final note = ChecklistNote(
        id: 'note-1',
        title: 'Tasks',
        items: const [
          ChecklistItem(
              id: 'i1', text: 'Checked first', isChecked: true, order: 0),
          ChecklistItem(
              id: 'i2', text: 'Unchecked second', isChecked: false, order: 1),
          ChecklistItem(
              id: 'i3', text: 'Unchecked third', isChecked: false, order: 2),
        ],
        createdAt: now,
        updatedAt: now,
      );
      await dataSource.createNote(note);

      await tester.pumpWidget(createDetailPage(note));
      await tester.pumpAndSettle();

      // Initially in flat mode, items in order
      var checkboxes =
          tester.widgetList<Checkbox>(find.byType(Checkbox)).toList();
      expect(checkboxes[0].value, true); // Checked first
      expect(checkboxes[1].value, false); // Unchecked second
      expect(checkboxes[2].value, false); // Unchecked third

      // Open display mode menu and tap "Checked at bottom"
      await tester.tap(find.byIcon(Icons.view_list));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Checked at bottom'));
      await tester.pumpAndSettle();

      // Now checked items should be at the bottom
      checkboxes =
          tester.widgetList<Checkbox>(find.byType(Checkbox)).toList();
      expect(checkboxes[0].value, false); // Unchecked second
      expect(checkboxes[1].value, false); // Unchecked third
      expect(checkboxes[2].value, true); // Checked first (moved to bottom)
    });

    testWidgets(
        'should delay move to bottom when checking an item in checked-at-bottom mode',
        (tester) async {
      final note = ChecklistNote(
        id: 'note-1',
        title: 'Tasks',
        items: const [
          ChecklistItem(
              id: 'i1', text: 'First', isChecked: false, order: 0),
          ChecklistItem(
              id: 'i2', text: 'Second', isChecked: false, order: 1),
        ],
        createdAt: now,
        updatedAt: now,
      );
      await dataSource.createNote(note);

      await tester.pumpWidget(createDetailPage(note));
      await tester.pumpAndSettle();

      // Enable checked at bottom
      await tester.tap(find.byIcon(Icons.view_list));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Checked at bottom'));
      await tester.pumpAndSettle();

      // Check the first item
      await tester.tap(find.byType(Checkbox).first);
      await tester.pump(); // Just one frame

      // Item should be checked but still in place (pending move)
      var checkboxes =
          tester.widgetList<Checkbox>(find.byType(Checkbox)).toList();
      expect(checkboxes[0].value, true); // Just checked, still first
      expect(checkboxes[1].value, false);

      // After the delay, it should move to the bottom
      await tester.pumpAndSettle();

      checkboxes =
          tester.widgetList<Checkbox>(find.byType(Checkbox)).toList();
      expect(checkboxes[0].value, false); // Second is now first
      expect(checkboxes[1].value, true); // First moved to bottom
    });

    testWidgets('should show separator between unchecked and checked items',
        (tester) async {
      final note = ChecklistNote(
        id: 'note-1',
        title: 'Tasks',
        items: const [
          ChecklistItem(
              id: 'i1', text: 'Done', isChecked: true, order: 0),
          ChecklistItem(
              id: 'i2', text: 'Todo', isChecked: false, order: 1),
        ],
        createdAt: now,
        updatedAt: now,
      );
      await dataSource.createNote(note);

      await tester.pumpWidget(createDetailPage(note));
      await tester.pumpAndSettle();

      // No separator initially
      expect(find.text('Checked'), findsNothing);

      // Enable checked at bottom
      await tester.tap(find.byIcon(Icons.view_list));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Checked at bottom'));
      await tester.pumpAndSettle();

      // Separator should appear between unchecked and checked sections
      expect(find.text('Checked'), findsOneWidget);
    });
  });

  group('Group by category mode', () {
    testWidgets('should show category headers when grouped by category',
        (tester) async {
      // Create categories
      await categoryDataSource.createCategory(
        const Category(id: 'cat-1', name: 'Work', colorValue: 0xFF2196F3),
      );
      await categoryDataSource.createCategory(
        const Category(id: 'cat-2', name: 'Shopping', colorValue: 0xFF4CAF50),
      );

      final note = ChecklistNote(
        id: 'note-1',
        title: 'Tasks',
        items: const [
          ChecklistItem(
              id: 'i1', text: 'Work task', order: 0, categoryId: 'cat-1'),
          ChecklistItem(
              id: 'i2', text: 'Buy milk', order: 1, categoryId: 'cat-2'),
          ChecklistItem(id: 'i3', text: 'No category', order: 2),
        ],
        createdAt: now,
        updatedAt: now,
      );
      await dataSource.createNote(note);

      await tester.pumpWidget(createDetailPage(note));
      await tester.pumpAndSettle();

      // Switch to grouped mode
      await tester.tap(find.byIcon(Icons.view_list));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Group by category'));
      await tester.pumpAndSettle();

      // Should show category headers
      expect(find.text('Work'), findsWidgets);
      expect(find.text('Shopping'), findsWidgets);
      expect(find.text('Uncategorized'), findsOneWidget);

      // All items should still be visible
      expect(find.text('Work task'), findsOneWidget);
      expect(find.text('Buy milk'), findsOneWidget);
      expect(find.text('No category'), findsOneWidget);
    });

    testWidgets(
        'should show item counts per category group',
        (tester) async {
      await categoryDataSource.createCategory(
        const Category(id: 'cat-1', name: 'Work', colorValue: 0xFF2196F3),
      );

      final note = ChecklistNote(
        id: 'note-1',
        title: 'Tasks',
        items: const [
          ChecklistItem(
              id: 'i1', text: 'Task 1', order: 0, categoryId: 'cat-1'),
          ChecklistItem(
              id: 'i2', text: 'Task 2', order: 1, categoryId: 'cat-1'),
          ChecklistItem(id: 'i3', text: 'Other', order: 2),
        ],
        createdAt: now,
        updatedAt: now,
      );
      await dataSource.createNote(note);

      await tester.pumpWidget(createDetailPage(note));
      await tester.pumpAndSettle();

      // Switch to grouped mode
      await tester.tap(find.byIcon(Icons.view_list));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Group by category'));
      await tester.pumpAndSettle();

      // Should show counts
      expect(find.text('(2)'), findsOneWidget); // Work group
      expect(find.text('(1)'), findsOneWidget); // Uncategorized group
    });

    testWidgets(
        'should move all checked items to full bottom when both modes are active',
        (tester) async {
      await categoryDataSource.createCategory(
        const Category(id: 'cat-1', name: 'Work', colorValue: 0xFF2196F3),
      );
      await categoryDataSource.createCategory(
        const Category(id: 'cat-2', name: 'Shopping', colorValue: 0xFF4CAF50),
      );

      final note = ChecklistNote(
        id: 'note-1',
        title: 'Tasks',
        items: const [
          ChecklistItem(
              id: 'i1',
              text: 'Done work',
              isChecked: true,
              order: 0,
              categoryId: 'cat-1'),
          ChecklistItem(
              id: 'i2',
              text: 'Pending work',
              isChecked: false,
              order: 1,
              categoryId: 'cat-1'),
          ChecklistItem(
              id: 'i3',
              text: 'Done shopping',
              isChecked: true,
              order: 2,
              categoryId: 'cat-2'),
          ChecklistItem(
              id: 'i4',
              text: 'Pending shopping',
              isChecked: false,
              order: 3,
              categoryId: 'cat-2'),
        ],
        createdAt: now,
        updatedAt: now,
      );
      await dataSource.createNote(note);

      await tester.pumpWidget(createDetailPage(note));
      await tester.pumpAndSettle();

      // Enable group by category
      await tester.tap(find.byIcon(Icons.view_list));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Group by category'));
      await tester.pumpAndSettle();

      // Enable checked at bottom
      await tester.tap(find.byIcon(Icons.view_list));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Checked at bottom'));
      await tester.pumpAndSettle();

      // Unchecked items from groups first, then all checked at the bottom
      final checkboxes =
          tester.widgetList<Checkbox>(find.byType(Checkbox)).toList();
      expect(checkboxes[0].value, false); // Pending work (Work group)
      expect(checkboxes[1].value, false); // Pending shopping (Shopping group)
      expect(checkboxes[2].value, true); // Done work (checked section)
      expect(checkboxes[3].value, true); // Done shopping (checked section)

      // Separator should be visible
      expect(find.text('Checked'), findsOneWidget);
    });
  });
}
