import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/constants/app_constants.dart';
import '../../data/datasources/checklist_datasource.dart';
import '../../data/datasources/local/fake_checklist_datasource.dart';
import '../../data/datasources/remote/supabase_checklist_datasource.dart';
import '../../data/repositories/checklist_repository_impl.dart';
import '../../domain/entities/checklist_note.dart';
import '../../domain/repositories/checklist_repository.dart';
import 'actor_providers.dart';
import 'workspace_providers.dart';

/// Provides the checklist data source instance (singleton).
/// Uses [SupabaseChecklistDataSource] in prod, [FakeChecklistDataSource] in dev.
final dataSourceProvider = Provider<ChecklistDataSource>((ref) {
  if (AppConstants.isProd) {
    return SupabaseChecklistDataSource(Supabase.instance.client);
  }
  return FakeChecklistDataSource();
});

/// Provides the repository instance
final checklistRepositoryProvider = Provider<ChecklistRepository>((ref) {
  return ChecklistRepositoryImpl(dataSource: ref.watch(dataSourceProvider));
});

/// State notifier for managing the list of checklist notes.
///
/// When a workspace is active, shows all notes where the creator or any
/// assignee is a workspace member (so all collaborators share the same view).
/// Falls back to filtering by the current actor alone when no workspace exists.
class ChecklistListNotifier
    extends StateNotifier<AsyncValue<List<ChecklistNote>>> {
  final ChecklistRepository _repository;
  final String? _currentActorId;
  final List<String> _workspaceMemberIds;

  ChecklistListNotifier(
    this._repository,
    this._currentActorId,
    this._workspaceMemberIds,
  ) : super(const AsyncValue.loading()) {
    loadNotes();
  }

  Future<void> loadNotes() async {
    state = const AsyncValue.loading();
    final result = await _repository.getAllNotes();
    result.fold(
      (failure) => state = AsyncValue.error(failure.message, StackTrace.current),
      (notes) {
        // Use workspace members when available, otherwise fall back to the
        // current actor only.
        final visibleIds = _workspaceMemberIds.isNotEmpty
            ? _workspaceMemberIds
            : (_currentActorId != null ? [_currentActorId] : <String>[]);

        if (visibleIds.isEmpty) {
          state = AsyncValue.data(notes);
          return;
        }

        final filtered = notes.where((n) {
          final creatorVisible =
              n.creatorId != null && visibleIds.contains(n.creatorId);
          final assigneeVisible =
              n.assigneeIds.any((id) => visibleIds.contains(id));
          return creatorVisible || assigneeVisible;
        }).toList();

        state = AsyncValue.data(filtered);
      },
    );
  }

  Future<void> deleteNote(String id) async {
    await _repository.deleteNote(id);
    await loadNotes();
  }
}

/// Provider for the checklist list.
/// Rebuilds when the current actor or workspace changes.
final checklistListProvider =
    StateNotifierProvider<ChecklistListNotifier, AsyncValue<List<ChecklistNote>>>(
        (ref) {
  final repository = ref.watch(checklistRepositoryProvider);
  final currentActor = ref.watch(currentActorProvider);
  final workspaceAsync = ref.watch(currentWorkspaceProvider);
  final workspace = workspaceAsync.valueOrNull;
  final memberIds = workspace?.memberIds ?? [];
  return ChecklistListNotifier(repository, currentActor?.id, memberIds);
});
