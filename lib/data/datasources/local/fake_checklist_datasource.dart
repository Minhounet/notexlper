import '../../../domain/entities/checklist_item.dart';
import '../../../domain/entities/checklist_note.dart';

/// Fake data source for development and testing.
/// Stores data in memory.
///
/// Use [delay] to control simulated network latency.
/// Set to [Duration.zero] in widget tests to avoid fake timer issues.
class FakeChecklistDataSource {
  final Map<String, ChecklistNote> _notes = {};
  final Duration delay;

  FakeChecklistDataSource({this.delay = const Duration(milliseconds: 100)}) {
    _seedData();
  }

  void _seedData() {
    final now = DateTime.now();
    final sampleNote = ChecklistNote(
      id: 'sample-1',
      title: 'Sample Checklist',
      items: [
        const ChecklistItem(
          id: 'item-1',
          text: 'First task',
          isChecked: false,
          order: 0,
        ),
        const ChecklistItem(
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
      creatorId: 'actor-1',
      assigneeIds: const ['actor-1'],
    );
    _notes[sampleNote.id] = sampleNote;
  }

  Future<void> _simulateDelay() async {
    if (delay > Duration.zero) {
      await Future.delayed(delay);
    }
  }

  Future<List<ChecklistNote>> getAllNotes() async {
    await _simulateDelay();
    return _notes.values.toList();
  }

  Future<ChecklistNote?> getNoteById(String id) async {
    await _simulateDelay();
    return _notes[id];
  }

  Future<ChecklistNote> createNote(ChecklistNote note) async {
    await _simulateDelay();
    _notes[note.id] = note;
    return note;
  }

  Future<ChecklistNote> updateNote(ChecklistNote note) async {
    await _simulateDelay();
    _notes[note.id] = note;
    return note;
  }

  Future<void> deleteNote(String id) async {
    await _simulateDelay();
    _notes.remove(id);
  }

  /// Clears all data - useful for testing
  void clear() {
    _notes.clear();
  }
}
