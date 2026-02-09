import 'package:dartz/dartz.dart';

import '../../core/error/failures.dart';
import '../../domain/entities/actor.dart';
import '../../domain/repositories/actor_repository.dart';
import '../datasources/local/fake_actor_datasource.dart';

/// Implementation of ActorRepository using the fake data source.
class ActorRepositoryImpl implements ActorRepository {
  final FakeActorDataSource dataSource;

  ActorRepositoryImpl({required this.dataSource});

  @override
  Future<Either<Failure, List<Actor>>> getAllActors() async {
    try {
      final actors = await dataSource.getAllActors();
      return Right(actors);
    } catch (e) {
      return const Left(CacheFailure('Failed to fetch actors'));
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
    } catch (e) {
      return const Left(CacheFailure('Failed to fetch actor'));
    }
  }
}
