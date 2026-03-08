import 'package:dartz/dartz.dart';

import '../../core/error/failures.dart';
import '../../core/logging/app_logger.dart';
import '../../domain/entities/actor.dart';
import '../../domain/repositories/actor_repository.dart';
import '../datasources/actor_datasource.dart';

/// Implementation of [ActorRepository].
/// Accepts any [ActorDataSource] — use [FakeActorDataSource] in dev,
/// a Supabase implementation in prod.
class ActorRepositoryImpl implements ActorRepository {
  final ActorDataSource dataSource;

  ActorRepositoryImpl({required this.dataSource});

  @override
  Future<Either<Failure, List<Actor>>> getAllActors() async {
    try {
      final actors = await dataSource.getAllActors();
      return Right(actors);
    } catch (e, s) {
      AppLogger.instance.log('getAllActors failed', error: e, stackTrace: s);
      return Left(CacheFailure('Failed to fetch actors: $e'));
    }
  }

  @override
  Future<Either<Failure, Actor>> getActorById(String id) async {
    try {
      final actor = await dataSource.getActorById(id);
      if (actor == null) {
        return const Left(NotFoundFailure('Actor not found'));
      }
      return Right(actor);
    } catch (e, s) {
      AppLogger.instance.log('getActorById($id) failed', error: e, stackTrace: s);
      return Left(CacheFailure('Failed to fetch actor: $e'));
    }
  }

  @override
  Future<Either<Failure, Actor>> createActor(Actor actor) async {
    try {
      final created = await dataSource.createActor(actor);
      return Right(created);
    } catch (e, s) {
      AppLogger.instance.log('createActor failed', error: e, stackTrace: s);
      return Left(CacheFailure('Failed to create actor: $e'));
    }
  }
}
