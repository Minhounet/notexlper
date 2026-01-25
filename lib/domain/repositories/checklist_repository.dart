import 'package:dartz/dartz.dart';

import '../../core/error/failures.dart';
import '../entities/checklist_note.dart';

/// Abstract repository interface for checklist operations.
/// Implementations can be fake (for dev) or real (Supabase for prod).
abstract class ChecklistRepository {
  /// Get all checklist notes
  Future<Either<Failure, List<ChecklistNote>>> getAllNotes();

  /// Get a single note by ID
  Future<Either<Failure, ChecklistNote>> getNoteById(String id);

  /// Create a new checklist note
  Future<Either<Failure, ChecklistNote>> createNote(ChecklistNote note);

  /// Update an existing note
  Future<Either<Failure, ChecklistNote>> updateNote(ChecklistNote note);

  /// Delete a note by ID
  Future<Either<Failure, void>> deleteNote(String id);

  /// Toggle the checked state of an item
  Future<Either<Failure, ChecklistNote>> toggleItemChecked(
    String noteId,
    String itemId,
  );
}
