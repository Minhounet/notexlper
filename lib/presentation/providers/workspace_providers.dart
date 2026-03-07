import 'package:dartz/dartz.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/constants/app_constants.dart';
import '../../core/error/failures.dart';
import '../../data/datasources/local/fake_workspace_datasource.dart';
import '../../data/datasources/remote/supabase_workspace_datasource.dart';
import '../../data/datasources/workspace_datasource.dart';
import '../../data/repositories/workspace_repository_impl.dart';
import '../../domain/entities/workspace.dart';
import '../../domain/repositories/workspace_repository.dart';

/// Provides the workspace data source (singleton, env-based).
final workspaceDataSourceProvider = Provider<WorkspaceDataSource>((ref) {
  if (AppConstants.isProd) {
    return SupabaseWorkspaceDataSource(Supabase.instance.client);
  }
  return FakeWorkspaceDataSource();
});

/// Provides the workspace repository instance.
final workspaceRepositoryProvider = Provider<WorkspaceRepository>((ref) {
  return WorkspaceRepositoryImpl(
    dataSource: ref.watch(workspaceDataSourceProvider),
  );
});

/// Notifier for the current actor's workspace.
/// Null means no workspace has been loaded yet.
class CurrentWorkspaceNotifier extends StateNotifier<AsyncValue<Workspace?>> {
  final WorkspaceRepository _repository;

  CurrentWorkspaceNotifier(this._repository)
      : super(const AsyncValue.data(null));

  /// Loads the workspace owned by [ownerId].
  Future<void> loadForOwner(String ownerId) async {
    state = const AsyncValue.loading();
    final result = await _repository.getWorkspaceForOwner(ownerId);
    result.fold(
      (failure) => state = AsyncValue.error(failure.message, StackTrace.current),
      (workspace) => state = AsyncValue.data(workspace),
    );
  }

  /// Creates a new workspace and stores it as the current workspace.
  Future<Either<Failure, Workspace>> createWorkspace(
      Workspace workspace) async {
    final result = await _repository.createWorkspace(workspace);
    result.fold(
      (failure) {},
      (created) => state = AsyncValue.data(created),
    );
    return result;
  }

  /// Invites [actorId] to the current workspace.
  Future<Either<Failure, Workspace>> addMember(
      String workspaceId, String actorId) async {
    final result = await _repository.addMember(workspaceId, actorId);
    result.fold(
      (failure) {},
      (updated) => state = AsyncValue.data(updated),
    );
    return result;
  }

  void clear() => state = const AsyncValue.data(null);
}

/// Provider for the current workspace.
final currentWorkspaceProvider = StateNotifierProvider<CurrentWorkspaceNotifier,
    AsyncValue<Workspace?>>((ref) {
  final repository = ref.watch(workspaceRepositoryProvider);
  return CurrentWorkspaceNotifier(repository);
});
