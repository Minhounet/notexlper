import '../../../domain/entities/checklist_item.dart';
import '../../../domain/entities/checklist_note.dart';

/// Fake data source for development and testing.
/// Stores data in memory.
class FakeChecklistDataSource {
  final Map<String, ChecklistNote> _notes = {};

  FakeChecklistDataSource() {
    _seedData();
  }

  void _seedData() {
    final now = DateTime.now();
    final sampleNote = ChecklistNote(
      id: 'sample-1',
      title: 'Sample Checklist',
      items: [
        ChecklistItem(
          id: 'item-1',
          text: 'First task',
          isChecked: false,
          order: 0,
        ),
        ChecklistItem(
          id: 'item-2',
          text: 'Second task',
          isChecked: true,
          order: 1,
        ),
        ChecklistItem(
          id: 'item-3',
          text: 'Third task with due date',
          isChecked: false,
          dueDate: now.add(const Duration(days: 7)),
          order: 2,
        ),
      ],
      createdAt: now,
      updatedAt: now,
    );
    _notes[sampleNote.id] = sampleNote;
  }

  Future<List<ChecklistNote>> getAllNotes() async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 100));
    return _notes.values.toList();
  }

  Future<ChecklistNote?> getNoteById(String id) async {
    await Future.delayed(const Duration(milliseconds: 50));
    return _notes[id];
  }

  Future<ChecklistNote> createNote(ChecklistNote note) async {
    await Future.delayed(const Duration(milliseconds: 100));
    _notes[note.id] = note;
    return note;
  }

  Future<ChecklistNote> updateNote(ChecklistNote note) async {
    await Future.delayed(const Duration(milliseconds: 100));
    _notes[note.id] = note;
    return note;
  }

  Future<void> deleteNote(String id) async {
    await Future.delayed(const Duration(milliseconds: 50));
    _notes.remove(id);
  }

  /// Clears all data - useful for testing
  void clear() {
    _notes.clear();
  }
}
