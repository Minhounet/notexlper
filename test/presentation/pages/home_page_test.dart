import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notexlper/data/datasources/local/fake_actor_datasource.dart';
import 'package:notexlper/data/datasources/local/fake_category_datasource.dart';
import 'package:notexlper/data/datasources/local/fake_checklist_datasource.dart';
import 'package:notexlper/domain/entities/actor.dart';
import 'package:notexlper/domain/entities/checklist_item.dart';
import 'package:notexlper/domain/entities/checklist_note.dart';
import 'package:notexlper/presentation/pages/home_page.dart';
import 'package:notexlper/presentation/providers/actor_providers.dart';
import 'package:notexlper/presentation/providers/category_providers.dart';
import 'package:notexlper/presentation/providers/checklist_providers.dart';

void main() {
  late FakeChecklistDataSource dataSource;
  late FakeCategoryDataSource categoryDataSource;
  late FakeActorDataSource actorDataSource;

  setUp(() {
    dataSource = FakeChecklistDataSource(delay: Duration.zero);
    dataSource.clear();
    categoryDataSource = FakeCategoryDataSource(delay: Duration.zero);
    categoryDataSource.clear();
    actorDataSource = FakeActorDataSource(delay: Duration.zero);
  });

  Widget createHomePage({FakeChecklistDataSource? ds}) {
    return ProviderScope(
      overrides: [
        dataSourceProvider.overrideWithValue(ds ?? dataSource),
        categoryDataSourceProvider.overrideWithValue(categoryDataSource),
        actorDataSourceProvider.overrideWithValue(actorDataSource),
      ],
      child: const MaterialApp(home: HomePage()),
    );
  }

  Widget createHomePageAsActor(Actor actor, {FakeChecklistDataSource? ds}) {
    return ProviderScope(
      overrides: [
        dataSourceProvider.overrideWithValue(ds ?? dataSource),
        categoryDataSourceProvider.overrideWithValue(categoryDataSource),
        actorDataSourceProvider.overrideWithValue(actorDataSource),
        currentActorProvider.overrideWith((ref) {
          final notifier = CurrentActorNotifier();
          notifier.login(actor);
          return notifier;
        }),
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

  group('HomePage - actor filtering', () {
    const actor1 = Actor(id: 'actor-1', name: 'Me', colorValue: 0xFF6200EE);
    const actor2 = Actor(id: 'actor-2', name: 'Alice', colorValue: 0xFF03DAC6);

    testWidgets('should only show checklists assigned to logged-in actor',
        (tester) async {
      final now = DateTime.now();
      await dataSource.createNote(ChecklistNote(
        id: 'note-1',
        title: 'My Checklist',
        items: const [
          ChecklistItem(id: 'i1', text: 'Task A', order: 0),
        ],
        createdAt: now,
        updatedAt: now,
        creatorId: 'actor-1',
        assigneeIds: const ['actor-1'],
      ));
      await dataSource.createNote(ChecklistNote(
        id: 'note-2',
        title: 'Alice Checklist',
        items: const [
          ChecklistItem(id: 'i2', text: 'Task B', order: 0),
        ],
        createdAt: now,
        updatedAt: now,
        creatorId: 'actor-2',
        assigneeIds: const ['actor-2'],
      ));

      await tester.pumpWidget(createHomePageAsActor(actor1));
      await tester.pumpAndSettle();

      expect(find.text('My Checklist'), findsOneWidget);
      expect(find.text('Alice Checklist'), findsNothing);
    });

    testWidgets('should show checklist assigned to multiple actors for each',
        (tester) async {
      final now = DateTime.now();
      await dataSource.createNote(ChecklistNote(
        id: 'note-1',
        title: 'Shared Checklist',
        items: const [
          ChecklistItem(id: 'i1', text: 'Shared task', order: 0),
        ],
        createdAt: now,
        updatedAt: now,
        creatorId: 'actor-1',
        assigneeIds: const ['actor-1', 'actor-2'],
      ));

      await tester.pumpWidget(createHomePageAsActor(actor1));
      await tester.pumpAndSettle();
      expect(find.text('Shared Checklist'), findsOneWidget);
    });

    testWidgets('should show empty state when actor has no assigned checklists',
        (tester) async {
      final now = DateTime.now();
      await dataSource.createNote(ChecklistNote(
        id: 'note-1',
        title: 'Only for Me',
        items: const [
          ChecklistItem(id: 'i1', text: 'Task', order: 0),
        ],
        createdAt: now,
        updatedAt: now,
        creatorId: 'actor-1',
        assigneeIds: const ['actor-1'],
      ));

      await tester.pumpWidget(createHomePageAsActor(actor2));
      await tester.pumpAndSettle();

      expect(find.text('Only for Me'), findsNothing);
      expect(find.text('No checklists yet'), findsOneWidget);
    });

    testWidgets('actor-2 should see only their checklists',
        (tester) async {
      final now = DateTime.now();
      await dataSource.createNote(ChecklistNote(
        id: 'note-1',
        title: 'My Checklist',
        items: const [
          ChecklistItem(id: 'i1', text: 'Task A', order: 0),
        ],
        createdAt: now,
        updatedAt: now,
        creatorId: 'actor-1',
        assigneeIds: const ['actor-1'],
      ));
      await dataSource.createNote(ChecklistNote(
        id: 'note-2',
        title: 'Alice Checklist',
        items: const [
          ChecklistItem(id: 'i2', text: 'Task B', order: 0),
        ],
        createdAt: now,
        updatedAt: now,
        creatorId: 'actor-2',
        assigneeIds: const ['actor-2'],
      ));

      await tester.pumpWidget(createHomePageAsActor(actor2));
      await tester.pumpAndSettle();

      expect(find.text('Alice Checklist'), findsOneWidget);
      expect(find.text('My Checklist'), findsNothing);
    });
  });
}
