import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notexlper/data/datasources/local/fake_checklist_datasource.dart';
import 'package:notexlper/domain/entities/checklist_item.dart';
import 'package:notexlper/domain/entities/checklist_note.dart';
import 'package:notexlper/presentation/pages/home_page.dart';
import 'package:notexlper/presentation/providers/checklist_providers.dart';

void main() {
  late FakeChecklistDataSource dataSource;

  setUp(() {
    dataSource = FakeChecklistDataSource();
    dataSource.clear();
  });

  Widget createHomePage({FakeChecklistDataSource? ds}) {
    return ProviderScope(
      overrides: [
        dataSourceProvider.overrideWithValue(ds ?? dataSource),
      ],
      child: const MaterialApp(home: HomePage()),
    );
  }

  group('HomePage', () {
    testWidgets('should show empty state when no checklists exist',
        (tester) async {
      await tester.pumpWidget(createHomePage());
      await tester.pumpAndSettle();

      expect(find.text('No checklists yet'), findsOneWidget);
      expect(find.text('Tap + to create your first checklist'), findsOneWidget);
    });

    testWidgets('should display existing checklists', (tester) async {
      final now = DateTime.now();
      await dataSource.createNote(ChecklistNote(
        id: 'note-1',
        title: 'Groceries',
        items: const [
          ChecklistItem(id: 'i1', text: 'Milk', isChecked: true, order: 0),
          ChecklistItem(id: 'i2', text: 'Bread', order: 1),
        ],
        createdAt: now,
        updatedAt: now,
      ));

      await tester.pumpWidget(createHomePage());
      await tester.pumpAndSettle();

      expect(find.text('Groceries'), findsOneWidget);
      expect(find.text('Milk'), findsOneWidget);
      expect(find.text('Bread'), findsOneWidget);
      expect(find.text('1/2 done'), findsOneWidget);
    });

    testWidgets('should show New Checklist FAB', (tester) async {
      await tester.pumpWidget(createHomePage());
      await tester.pumpAndSettle();

      expect(find.text('New Checklist'), findsOneWidget);
      expect(find.byIcon(Icons.add), findsOneWidget);
    });

    testWidgets('should navigate to detail page when tapping New Checklist',
        (tester) async {
      await tester.pumpWidget(createHomePage());
      await tester.pumpAndSettle();

      await tester.tap(find.text('New Checklist'));
      await tester.pumpAndSettle();

      // Should be on the detail page now
      expect(find.text('New Checklist'), findsOneWidget);
      expect(find.text('Checklist title'), findsOneWidget);
    });

    testWidgets('should navigate to detail page when tapping a checklist card',
        (tester) async {
      final now = DateTime.now();
      await dataSource.createNote(ChecklistNote(
        id: 'note-1',
        title: 'My Tasks',
        items: const [
          ChecklistItem(id: 'i1', text: 'Do laundry', order: 0),
        ],
        createdAt: now,
        updatedAt: now,
      ));

      await tester.pumpWidget(createHomePage());
      await tester.pumpAndSettle();

      await tester.tap(find.text('My Tasks'));
      await tester.pumpAndSettle();

      // Should be on detail page with the title
      expect(find.text('My Tasks'), findsWidgets);
      expect(find.text('Do laundry'), findsOneWidget);
    });

    testWidgets('should show delete confirmation dialog', (tester) async {
      final now = DateTime.now();
      await dataSource.createNote(ChecklistNote(
        id: 'note-1',
        title: 'To Delete',
        items: const [
          ChecklistItem(id: 'i1', text: 'Item', order: 0),
        ],
        createdAt: now,
        updatedAt: now,
      ));

      await tester.pumpWidget(createHomePage());
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.delete_outline));
      await tester.pumpAndSettle();

      expect(find.text('Delete checklist?'), findsOneWidget);
      expect(find.text('This action cannot be undone.'), findsOneWidget);
    });

    testWidgets('should delete checklist when confirmed', (tester) async {
      final now = DateTime.now();
      await dataSource.createNote(ChecklistNote(
        id: 'note-1',
        title: 'To Delete',
        items: const [
          ChecklistItem(id: 'i1', text: 'Item', order: 0),
        ],
        createdAt: now,
        updatedAt: now,
      ));

      await tester.pumpWidget(createHomePage());
      await tester.pumpAndSettle();

      expect(find.text('To Delete'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.delete_outline));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();

      expect(find.text('To Delete'), findsNothing);
      expect(find.text('No checklists yet'), findsOneWidget);
    });

    testWidgets('should display multiple checklists', (tester) async {
      final now = DateTime.now();
      await dataSource.createNote(ChecklistNote(
        id: 'note-1',
        title: 'First List',
        items: const [
          ChecklistItem(id: 'i1', text: 'Item A', order: 0),
        ],
        createdAt: now,
        updatedAt: now,
      ));
      await dataSource.createNote(ChecklistNote(
        id: 'note-2',
        title: 'Second List',
        items: const [
          ChecklistItem(id: 'i2', text: 'Item B', order: 0),
        ],
        createdAt: now,
        updatedAt: now,
      ));

      await tester.pumpWidget(createHomePage());
      await tester.pumpAndSettle();

      expect(find.text('First List'), findsOneWidget);
      expect(find.text('Second List'), findsOneWidget);
    });
  });
}
