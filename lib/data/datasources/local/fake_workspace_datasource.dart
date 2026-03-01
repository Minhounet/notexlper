import '../../../domain/entities/workspace.dart';
import '../workspace_datasource.dart';

/// In-memory workspace data source for development and testing.
class FakeWorkspaceDataSource implements WorkspaceDataSource {
  final Map<String, Workspace> _workspaces = {};

  // Maps ownerId → workspaceId for fast owner lookup.
  final Map<String, String> _ownerIndex = {};

  final Duration delay;

  FakeWorkspaceDataSource({this.delay = const Duration(milliseconds: 100)});

  Future<void> _simulateDelay() async {
    if (delay > Duration.zero) await Future.delayed(delay);
  }

  @override
  Future<Workspace?> getWorkspaceByOwnerId(String ownerId) async {
    await _simulateDelay();
    final workspaceId = _ownerIndex[ownerId];
    return workspaceId != null ? _workspaces[workspaceId] : null;
  }

  @override
  Future<Workspace> createWorkspace(Workspace workspace) async {
    await _simulateDelay();
    _workspaces[workspace.id] = workspace;
    _ownerIndex[workspace.ownerId] = workspace.id;
    return workspace;
  }

  @override
  Future<Workspace> addMember(String workspaceId, String actorId) async {
    await _simulateDelay();
    final workspace = _workspaces[workspaceId];
    if (workspace == null) throw StateError('Workspace $workspaceId not found');
    if (workspace.memberIds.contains(actorId)) return workspace;
    final updated = workspace.copyWith(
      memberIds: [...workspace.memberIds, actorId],
    );
    _workspaces[workspaceId] = updated;
    return updated;
  }

  /// Clears all data – useful for tests.
  void clear() {
    _workspaces.clear();
    _ownerIndex.clear();
  }
}
