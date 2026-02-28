import '../../domain/entities/checklist_note.dart';

/// Abstract data source interface for checklist notes.
///
/// In dev mode, use [FakeChecklistDataSource].
/// In prod, implement with Supabase.
abstract class ChecklistDataSource {
  Future<List<ChecklistNote>> getAllNotes();
  Future<ChecklistNote?> getNoteById(String id);
  Future<ChecklistNote> createNote(ChecklistNote note);
  Future<ChecklistNote> updateNote(ChecklistNote note);
  Future<void> deleteNote(String id);
}
