import 'package:dartz/dartz.dart';

import '../../core/error/failures.dart';
import '../../domain/entities/checklist_note.dart';
import '../../domain/repositories/checklist_repository.dart';
import '../datasources/checklist_datasource.dart';

/// Implementation of [ChecklistRepository].
/// Accepts any [ChecklistDataSource] — use [FakeChecklistDataSource] in dev,
/// a Supabase implementation in prod.
class ChecklistRepositoryImpl implements ChecklistRepository {
  final ChecklistDataSource dataSource;

  ChecklistRepositoryImpl({required this.dataSource});

  @override
  Future<Either<Failure, List<ChecklistNote>>> getAllNotes() async {
    try {
      final notes = await dataSource.getAllNotes();
      return Right(notes);
    } catch (e) {
      return const Left(CacheFailure('Failed to fetch notes'));
    }
  }

  @override
  Future<Either<Failure, ChecklistNote>> getNoteById(String id) async {
    try {
      final note = await dataSource.getNoteById(id);
      if (note == null) {
        return const Left(NotFoundFailure('Note not found'));
      }
      return Right(note);
    } catch (e) {
      return const Left(CacheFailure('Failed to fetch note'));
    }
  }

  @override
  Future<Either<Failure, ChecklistNote>> createNote(ChecklistNote note) async {
    try {
      final created = await dataSource.createNote(note);
      return Right(created);
    } catch (e) {
      return const Left(CacheFailure('Failed to create note'));
    }
  }

  @override
  Future<Either<Failure, ChecklistNote>> updateNote(ChecklistNote note) async {
    try {
      final updated = await dataSource.updateNote(note);
      return Right(updated);
    } catch (e) {
      return const Left(CacheFailure('Failed to update note'));
    }
  }

  @override
  Future<Either<Failure, void>> deleteNote(String id) async {
    try {
      await dataSource.deleteNote(id);
      return const Right(null);
    } catch (e) {
      return const Left(CacheFailure('Failed to delete note'));
    }
  }

  @override
  Future<Either<Failure, ChecklistNote>> toggleItemChecked(
    String noteId,
    String itemId,
  ) async {
    try {
      final note = await dataSource.getNoteById(noteId);
      if (note == null) {
        return const Left(NotFoundFailure('Note not found'));
      }

      final updatedItems = note.items.map((item) {
        if (item.id == itemId) {
          return item.copyWith(isChecked: !item.isChecked);
        }
        return item;
      }).toList();

      final updatedNote = note.copyWith(
        items: updatedItems,
        updatedAt: DateTime.now(),
      );

      await dataSource.updateNote(updatedNote);
      return Right(updatedNote);
    } catch (e) {
      return const Left(CacheFailure('Failed to toggle item'));
    }
  }
}
