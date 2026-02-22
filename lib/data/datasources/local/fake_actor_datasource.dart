import '../../../domain/entities/actor.dart';
import '../actor_datasource.dart';

/// Fake data source for actors in development and testing.
/// Seeds two actors for the workspace.
class FakeActorDataSource implements ActorDataSource {
  final Map<String, Actor> _actors = {};
  final Duration delay;

  FakeActorDataSource({this.delay = const Duration(milliseconds: 100)}) {
    _seedData();
  }

  void _seedData() {
    const me = Actor(
      id: 'actor-1',
      name: 'Me',
      colorValue: 0xFF6200EE, // deep purple
    );
    const other = Actor(
      id: 'actor-2',
      name: 'Alice',
      colorValue: 0xFF03DAC6, // teal
    );
    _actors[me.id] = me;
    _actors[other.id] = other;
  }

  Future<void> _simulateDelay() async {
    if (delay > Duration.zero) {
      await Future.delayed(delay);
    }
  }

  @override
  Future<List<Actor>> getAllActors() async {
    await _simulateDelay();
    return _actors.values.toList();
  }

  @override
  Future<Actor?> getActorById(String id) async {
    await _simulateDelay();
    return _actors[id];
  }

  /// Clears all data - useful for testing
  void clear() {
    _actors.clear();
  }
}
