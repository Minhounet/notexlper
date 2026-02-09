import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/datasources/local/fake_actor_datasource.dart';
import '../../data/repositories/actor_repository_impl.dart';
import '../../domain/entities/actor.dart';
import '../../domain/repositories/actor_repository.dart';

/// Provides the actor data source instance (singleton)
final actorDataSourceProvider = Provider<FakeActorDataSource>((ref) {
  return FakeActorDataSource();
});

/// Provides the actor repository instance
final actorRepositoryProvider = Provider<ActorRepository>((ref) {
  return ActorRepositoryImpl(dataSource: ref.watch(actorDataSourceProvider));
});

/// Notifier for the currently logged-in actor.
/// Null means no actor is logged in yet.
class CurrentActorNotifier extends StateNotifier<Actor?> {
  CurrentActorNotifier() : super(null);

  void login(Actor actor) {
    state = actor;
  }

  void logout() {
    state = null;
  }
}

/// Provider for the currently logged-in actor
final currentActorProvider =
    StateNotifierProvider<CurrentActorNotifier, Actor?>((ref) {
  return CurrentActorNotifier();
});

/// State notifier for managing the list of actors in the workspace
class ActorListNotifier extends StateNotifier<AsyncValue<List<Actor>>> {
  final ActorRepository _repository;

  ActorListNotifier(this._repository) : super(const AsyncValue.loading()) {
    loadActors();
  }

  Future<void> loadActors() async {
    state = const AsyncValue.loading();
    final result = await _repository.getAllActors();
    result.fold(
      (failure) => state = AsyncValue.error(failure.message, StackTrace.current),
      (actors) => state = AsyncValue.data(actors),
    );
  }
}

/// Provider for the actor list
final actorListProvider =
    StateNotifierProvider<ActorListNotifier, AsyncValue<List<Actor>>>((ref) {
  final repository = ref.watch(actorRepositoryProvider);
  return ActorListNotifier(repository);
});
