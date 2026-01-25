import 'package:flutter_test/flutter_test.dart';
import 'package:notexlper/data/datasources/local/fake_checklist_datasource.dart';
import 'package:notexlper/data/repositories/checklist_repository_impl.dart';
import 'package:notexlper/domain/entities/checklist_item.dart';
import 'package:notexlper/domain/entities/checklist_note.dart';

void main() {
  late FakeChecklistDataSource dataSource;
  late ChecklistRepositoryImpl repository;

  setUp(() {
    dataSource = FakeChecklistDataSource();
    dataSource.clear(); // Start with clean state
    repository = ChecklistRepositoryImpl(dataSource: dataSource);
  });

  group('ChecklistRepositoryImpl', () {
    final testNote = ChecklistNote(
      id: 'test-note-1',
      title: 'Test Note',
      items: const [
        ChecklistItem(id: 'item-1', text: 'Task 1'),
        ChecklistItem(id: 'item-2', text: 'Task 2'),
      ],
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    group('createNote', () {
      test('should create a note and return it', () async {
        final result = await repository.createNote(testNote);

        expect(result.isRight(), true);
        result.fold(
          (failure) => fail('Should not return failure'),
          (note) {
            expect(note.id, testNote.id);
            expect(note.title, testNote.title);
          },
        );
      });
    });

    group('getAllNotes', () {
      test('should return empty list when no notes exist', () async {
        final result = await repository.getAllNotes();

        expect(result.isRight(), true);
        result.fold(
          (failure) => fail('Should not return failure'),
          (notes) => expect(notes, isEmpty),
        );
      });

      test('should return all created notes', () async {
        await repository.createNote(testNote);

        final result = await repository.getAllNotes();

        expect(result.isRight(), true);
        result.fold(
          (failure) => fail('Should not return failure'),
          (notes) => expect(notes.length, 1),
        );
      });
    });

    group('getNoteById', () {
      test('should return note when it exists', () async {
        await repository.createNote(testNote);

        final result = await repository.getNoteById(testNote.id);

        expect(result.isRight(), true);
        result.fold(
          (failure) => fail('Should not return failure'),
          (note) => expect(note.id, testNote.id),
        );
      });

      test('should return NotFoundFailure when note does not exist', () async {
        final result = await repository.getNoteById('non-existent');

        expect(result.isLeft(), true);
      });
    });

    group('toggleItemChecked', () {
      test('should toggle item checked state', () async {
        await repository.createNote(testNote);

        final result = await repository.toggleItemChecked(
          testNote.id,
          'item-1',
        );

        expect(result.isRight(), true);
        result.fold(
          (failure) => fail('Should not return failure'),
          (note) {
            final item = note.items.firstWhere((i) => i.id == 'item-1');
            expect(item.isChecked, true);
          },
        );
      });
    });

    group('deleteNote', () {
      test('should delete existing note', () async {
        await repository.createNote(testNote);

        final deleteResult = await repository.deleteNote(testNote.id);
        expect(deleteResult.isRight(), true);

        final getResult = await repository.getNoteById(testNote.id);
        expect(getResult.isLeft(), true);
      });
    });
  });
}
