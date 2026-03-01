import '../../domain/entities/workspace.dart';

/// Abstract data source interface for workspace operations.
abstract class WorkspaceDataSource {
  /// Returns the workspace owned by [ownerId], or null if none exists.
  Future<Workspace?> getWorkspaceByOwnerId(String ownerId);

  /// Persists a new workspace. Returns the created workspace.
  Future<Workspace> createWorkspace(Workspace workspace);

  /// Adds [actorId] as a member of [workspaceId]. Returns the updated workspace.
  Future<Workspace> addMember(String workspaceId, String actorId);
}
