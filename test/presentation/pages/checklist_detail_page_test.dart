import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notexlper/data/datasources/local/fake_checklist_datasource.dart';
import 'package:notexlper/domain/entities/checklist_item.dart';
import 'package:notexlper/domain/entities/checklist_note.dart';
import 'package:notexlper/presentation/pages/checklist_detail_page.dart';
import 'package:notexlper/presentation/providers/checklist_providers.dart';

void main() {
  late FakeChecklistDataSource dataSource;
  final now = DateTime(2024, 6, 1);

  setUp(() {
    dataSource = FakeChecklistDataSource(delay: Duration.zero);
    dataSource.clear();
  });

  Widget createDetailPage(ChecklistNote note) {
    return ProviderScope(
      overrides: [
        dataSourceProvider.overrideWithValue(dataSource),
      ],
      child: MaterialApp(home: ChecklistDetailPage(note: note)),
    );
  }

  Widget createDetailPageWithNavigation(ChecklistNote note) {
    return ProviderScope(
      overrides: [
        dataSourceProvider.overrideWithValue(dataSource),
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
}
