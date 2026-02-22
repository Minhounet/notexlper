import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/datasources/checklist_datasource.dart';
import '../../data/datasources/local/fake_checklist_datasource.dart';
import '../../data/repositories/checklist_repository_impl.dart';
import '../../domain/entities/checklist_note.dart';
import '../../domain/repositories/checklist_repository.dart';
import 'actor_providers.dart';

/// Provides the data source instance (singleton).
/// Returns [ChecklistDataSource] so the implementation can be swapped
/// without changing callers. Currently uses [FakeChecklistDataSource] for
/// both dev and prod until a Supabase implementation is available.
final dataSourceProvider = Provider<ChecklistDataSource>((ref) {
  return FakeChecklistDataSource();
});

/// Provides the repository instance
final checklistRepositoryProvider = Provider<ChecklistRepository>((ref) {
  return ChecklistRepositoryImpl(dataSource: ref.watch(dataSourceProvider));
});

/// State notifier for managing the list of checklist notes.
/// Filters notes to only show those assigned to [currentActorId].
class ChecklistListNotifier extends StateNotifier<AsyncValue<List<ChecklistNote>>> {
  final ChecklistRepository _repository;
  final String? _currentActorId;

  ChecklistListNotifier(this._repository, this._currentActorId)
      : super(const AsyncValue.loading()) {
    loadNotes();
  }

  Future<void> loadNotes() async {
    state = const AsyncValue.loading();
    final result = await _repository.getAllNotes();
    result.fold(
      (failure) => state = AsyncValue.error(failure.message, StackTrace.current),
      (notes) {
        if (_currentActorId != null) {
          final filtered = notes
              .where((n) => n.assigneeIds.contains(_currentActorId))
              .toList();
          state = AsyncValue.data(filtered);
        } else {
          state = AsyncValue.data(notes);
        }
      },
    );
  }

  Future<void> deleteNote(String id) async {
    await _repository.deleteNote(id);
    await loadNotes();
  }
}

/// Provider for the checklist list.
/// Rebuilds when the current actor changes so filtering is applied.
final checklistListProvider =
    StateNotifierProvider<ChecklistListNotifier, AsyncValue<List<ChecklistNote>>>((ref) {
  final repository = ref.watch(checklistRepositoryProvider);
  final currentActor = ref.watch(currentActorProvider);
  return ChecklistListNotifier(repository, currentActor?.id);
});
