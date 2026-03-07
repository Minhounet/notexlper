import 'package:dartz/dartz.dart';

import '../../core/error/failures.dart';
import '../../core/logging/app_logger.dart';
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
    } catch (e, s) {
      AppLogger.instance.log('getAllNotes failed', error: e, stackTrace: s);
      return Left(CacheFailure('Failed to fetch notes: $e'));
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
    } catch (e, s) {
      AppLogger.instance.log('getNoteById($id) failed', error: e, stackTrace: s);
      return Left(CacheFailure('Failed to fetch note: $e'));
    }
  }

  @override
  Future<Either<Failure, ChecklistNote>> createNote(ChecklistNote note) async {
    try {
      final created = await dataSource.createNote(note);
      return Right(created);
    } catch (e, s) {
      AppLogger.instance.log('createNote failed', error: e, stackTrace: s);
      return Left(CacheFailure('Failed to create note: $e'));
    }
  }

  @override
  Future<Either<Failure, ChecklistNote>> updateNote(ChecklistNote note) async {
    try {
      final updated = await dataSource.updateNote(note);
      return Right(updated);
    } catch (e, s) {
      AppLogger.instance.log('updateNote(${note.id}) failed', error: e, stackTrace: s);
      return Left(CacheFailure('Failed to update note: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> deleteNote(String id) async {
    try {
      await dataSource.deleteNote(id);
      return const Right(null);
    } catch (e, s) {
      AppLogger.instance.log('deleteNote($id) failed', error: e, stackTrace: s);
      return Left(CacheFailure('Failed to delete note: $e'));
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
    } catch (e, s) {
      AppLogger.instance
          .log('toggleItemChecked($noteId, $itemId) failed', error: e, stackTrace: s);
      return Left(CacheFailure('Failed to toggle item: $e'));
    }
  }
}
