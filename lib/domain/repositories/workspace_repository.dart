import 'package:dartz/dartz.dart';

import '../../core/error/failures.dart';
import '../entities/workspace.dart';

/// Abstract repository interface for workspace operations.
abstract class WorkspaceRepository {
  /// Get the workspace owned by the given actor.
  /// Returns [NotFoundFailure] if no workspace exists for that owner.
  Future<Either<Failure, Workspace?>> getWorkspaceForOwner(String ownerId);

  /// Create a new workspace.
  Future<Either<Failure, Workspace>> createWorkspace(Workspace workspace);

  /// Add an actor as a member of a workspace.
  Future<Either<Failure, Workspace>> addMember(
      String workspaceId, String actorId);
}
