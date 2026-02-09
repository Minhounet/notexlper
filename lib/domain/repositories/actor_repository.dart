import 'package:dartz/dartz.dart';

import '../../core/error/failures.dart';
import '../entities/actor.dart';

/// Abstract repository interface for actor operations.
abstract class ActorRepository {
  /// Get all actors in the workspace
  Future<Either<Failure, List<Actor>>> getAllActors();

  /// Get a single actor by ID
  Future<Either<Failure, Actor>> getActorById(String id);
}
