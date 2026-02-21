import 'package:flutter_test/flutter_test.dart';
import 'package:notexlper/domain/entities/checklist_item.dart';
import 'package:notexlper/domain/entities/checklist_note.dart';
import 'package:notexlper/domain/entities/reminder.dart';

void main() {
  group('ChecklistNote', () {
    final now = DateTime(2024, 1, 15);

    ChecklistNote createNote({List<ChecklistItem>? items}) {
      return ChecklistNote(
        id: 'test-id',
        title: 'Test Note',
        items: items ?? [],
        createdAt: now,
        updatedAt: now,
      );
    }

    test('should return correct completedCount', () {
      final note = createNote(
        items: [
          const ChecklistItem(id: '1', text: 'Task 1', isChecked: true),
          const ChecklistItem(id: '2', text: 'Task 2', isChecked: false),
          const ChecklistItem(id: '3', text: 'Task 3', isChecked: true),
        ],
      );

      expect(note.completedCount, 2);
    });

    test('should return correct totalCount', () {
      final note = createNote(
        items: [
          const ChecklistItem(id: '1', text: 'Task 1'),
          const ChecklistItem(id: '2', text: 'Task 2'),
        ],
      );

      expect(note.totalCount, 2);
    });

    test('isCompleted should return true when all items are checked', () {
      final note = createNote(
        items: [
          const ChecklistItem(id: '1', text: 'Task 1', isChecked: true),
          const ChecklistItem(id: '2', text: 'Task 2', isChecked: true),
        ],
      );

      expect(note.isCompleted, true);
    });

    test('isCompleted should return false when not all items are checked', () {
      final note = createNote(
        items: [
          const ChecklistItem(id: '1', text: 'Task 1', isChecked: true),
          const ChecklistItem(id: '2', text: 'Task 2', isChecked: false),
        ],
      );

      expect(note.isCompleted, false);
    });

    test('isCompleted should return false when there are no items', () {
      final note = createNote(items: []);

      expect(note.isCompleted, false);
    });

    test('sortedItems should return items sorted by order', () {
      final note = createNote(
        items: [
          const ChecklistItem(id: '1', text: 'Task 3', order: 2),
          const ChecklistItem(id: '2', text: 'Task 1', order: 0),
          const ChecklistItem(id: '3', text: 'Task 2', order: 1),
        ],
      );

      final sorted = note.sortedItems;

      expect(sorted[0].text, 'Task 1');
      expect(sorted[1].text, 'Task 2');
      expect(sorted[2].text, 'Task 3');
    });

    test('copyWith should create a copy with updated values', () {
      final note = createNote();
      final updatedNote = note.copyWith(title: 'Updated Title', isPinned: true);

      expect(updatedNote.title, 'Updated Title');
      expect(updatedNote.isPinned, true);
      expect(updatedNote.id, note.id);
    });

    test('two notes with same properties should be equal', () {
      final note1 = createNote();
      final note2 = createNote();

      expect(note1, note2);
    });

    test('should have default empty assigneeIds and null creatorId', () {
      final note = createNote();

      expect(note.creatorId, isNull);
      expect(note.assigneeIds, isEmpty);
    });

    test('should store creatorId and assigneeIds', () {
      final note = ChecklistNote(
        id: 'test-id',
        title: 'Test',
        items: const [],
        createdAt: now,
        updatedAt: now,
        creatorId: 'actor-1',
        assigneeIds: const ['actor-1', 'actor-2'],
      );

      expect(note.creatorId, 'actor-1');
      expect(note.assigneeIds, ['actor-1', 'actor-2']);
    });

    test('copyWith should update creatorId and assigneeIds', () {
      final note = createNote();
      final updated = note.copyWith(
        creatorId: 'actor-1',
        assigneeIds: ['actor-1'],
      );

      expect(updated.creatorId, 'actor-1');
      expect(updated.assigneeIds, ['actor-1']);
      expect(updated.id, note.id);
    });

    test('notes with different assigneeIds should not be equal', () {
      final note1 = ChecklistNote(
        id: 'test-id',
        title: 'Test',
        items: const [],
        createdAt: now,
        updatedAt: now,
        assigneeIds: const ['actor-1'],
      );
      final note2 = ChecklistNote(
        id: 'test-id',
        title: 'Test',
        items: const [],
        createdAt: now,
        updatedAt: now,
        assigneeIds: const ['actor-2'],
      );

      expect(note1, isNot(note2));
    });

    test('should have null reminder by default', () {
      final note = createNote();

      expect(note.reminder, isNull);
      expect(note.hasActiveReminder, false);
    });

    test('should store reminder', () {
      final reminder = Reminder(
        id: 'r-1',
        dateTime: DateTime(2025, 6, 15, 9, 0),
        frequency: ReminderFrequency.weekly,
      );
      final note = ChecklistNote(
        id: 'test-id',
        title: 'Test',
        items: const [],
        createdAt: now,
        updatedAt: now,
        reminder: reminder,
      );

      expect(note.reminder, reminder);
      expect(note.hasActiveReminder, true);
    });

    test('hasActiveReminder should be false when reminder is disabled', () {
      final reminder = Reminder(
        id: 'r-1',
        dateTime: DateTime(2025, 6, 15, 9, 0),
        isEnabled: false,
      );
      final note = ChecklistNote(
        id: 'test-id',
        title: 'Test',
        items: const [],
        createdAt: now,
        updatedAt: now,
        reminder: reminder,
      );

      expect(note.hasActiveReminder, false);
    });

    test('copyWith should update reminder', () {
      final note = createNote();
      final reminder = Reminder(
        id: 'r-1',
        dateTime: DateTime(2025, 6, 15, 9, 0),
      );
      final updated = note.copyWith(reminder: reminder);

      expect(updated.reminder, reminder);
      expect(updated.hasActiveReminder, true);
    });

    test('copyWith with clearReminder should remove reminder', () {
      final reminder = Reminder(
        id: 'r-1',
        dateTime: DateTime(2025, 6, 15, 9, 0),
      );
      final note = ChecklistNote(
        id: 'test-id',
        title: 'Test',
        items: const [],
        createdAt: now,
        updatedAt: now,
        reminder: reminder,
      );

      final cleared = note.copyWith(clearReminder: true);

      expect(cleared.reminder, isNull);
      expect(cleared.hasActiveReminder, false);
    });

    test('notes with different reminders should not be equal', () {
      final r1 = Reminder(
        id: 'r-1',
        dateTime: DateTime(2025, 6, 15, 9, 0),
      );
      final r2 = Reminder(
        id: 'r-1',
        dateTime: DateTime(2025, 6, 16, 9, 0),
      );
      final note1 = ChecklistNote(
        id: 'test-id',
        title: 'Test',
        items: const [],
        createdAt: now,
        updatedAt: now,
        reminder: r1,
      );
      final note2 = ChecklistNote(
        id: 'test-id',
        title: 'Test',
        items: const [],
        createdAt: now,
        updatedAt: now,
        reminder: r2,
      );

      expect(note1, isNot(note2));
    });
  });
}
