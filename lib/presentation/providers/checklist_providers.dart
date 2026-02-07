import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/datasources/local/fake_checklist_datasource.dart';
import '../../data/repositories/checklist_repository_impl.dart';
import '../../domain/entities/checklist_note.dart';
import '../../domain/repositories/checklist_repository.dart';

/// Provides the data source instance (singleton)
final dataSourceProvider = Provider<FakeChecklistDataSource>((ref) {
  return FakeChecklistDataSource();
});

/// Provides the repository instance
final checklistRepositoryProvider = Provider<ChecklistRepository>((ref) {
  return ChecklistRepositoryImpl(dataSource: ref.watch(dataSourceProvider));
});

/// State notifier for managing the list of checklist notes
class ChecklistListNotifier extends StateNotifier<AsyncValue<List<ChecklistNote>>> {
  final ChecklistRepository _repository;

  ChecklistListNotifier(this._repository) : super(const AsyncValue.loading()) {
    loadNotes();
  }

  Future<void> loadNotes() async {
    state = const AsyncValue.loading();
    final result = await _repository.getAllNotes();
    result.fold(
      (failure) => state = AsyncValue.error(failure.message, StackTrace.current),
      (notes) => state = AsyncValue.data(notes),
    );
  }

  Future<void> deleteNote(String id) async {
    await _repository.deleteNote(id);
    await loadNotes();
  }
}

/// Provider for the checklist list
final checklistListProvider =
    StateNotifierProvider<ChecklistListNotifier, AsyncValue<List<ChecklistNote>>>((ref) {
  final repository = ref.watch(checklistRepositoryProvider);
  return ChecklistListNotifier(repository);
});
