import '../../domain/entities/actor.dart';

/// Abstract data source interface for actors.
///
/// In dev mode, use [FakeActorDataSource].
/// In prod, implement with Supabase.
abstract class ActorDataSource {
  Future<List<Actor>> getAllActors();
  Future<Actor?> getActorById(String id);
}
