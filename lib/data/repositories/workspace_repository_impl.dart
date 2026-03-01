import 'package:dartz/dartz.dart';

import '../../core/error/failures.dart';
import '../../domain/entities/workspace.dart';
import '../../domain/repositories/workspace_repository.dart';
import '../datasources/workspace_datasource.dart';

/// Concrete implementation of [WorkspaceRepository].
class WorkspaceRepositoryImpl implements WorkspaceRepository {
  final WorkspaceDataSource dataSource;

  WorkspaceRepositoryImpl({required this.dataSource});

  @override
  Future<Either<Failure, Workspace?>> getWorkspaceForOwner(
      String ownerId) async {
    try {
      final workspace = await dataSource.getWorkspaceByOwnerId(ownerId);
      return Right(workspace);
    } catch (e) {
      return const Left(CacheFailure('Failed to fetch workspace'));
    }
  }

  @override
  Future<Either<Failure, Workspace>> createWorkspace(
      Workspace workspace) async {
    try {
      final created = await dataSource.createWorkspace(workspace);
      return Right(created);
    } catch (e) {
      return const Left(CacheFailure('Failed to create workspace'));
    }
  }

  @override
  Future<Either<Failure, Workspace>> addMember(
      String workspaceId, String actorId) async {
    try {
      final updated = await dataSource.addMember(workspaceId, actorId);
      return Right(updated);
    } catch (e) {
      return const Left(CacheFailure('Failed to add workspace member'));
    }
  }
}
