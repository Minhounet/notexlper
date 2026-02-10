import 'package:flutter_test/flutter_test.dart';
import 'package:notexlper/domain/entities/actor.dart';

void main() {
  group('Actor', () {
    test('should create an actor with required fields', () {
      const actor = Actor(
        id: 'actor-1',
        name: 'Me',
        colorValue: 0xFF6200EE,
      );

      expect(actor.id, 'actor-1');
      expect(actor.name, 'Me');
      expect(actor.colorValue, 0xFF6200EE);
    });

    test('copyWith should create a copy with updated values', () {
      const actor = Actor(
        id: 'actor-1',
        name: 'Me',
        colorValue: 0xFF6200EE,
      );

      final updated = actor.copyWith(name: 'Alice');

      expect(updated.name, 'Alice');
      expect(updated.id, 'actor-1');
      expect(updated.colorValue, 0xFF6200EE);
    });

    test('copyWith should update color', () {
      const actor = Actor(
        id: 'actor-1',
        name: 'Me',
        colorValue: 0xFF6200EE,
      );

      final updated = actor.copyWith(colorValue: 0xFF03DAC6);

      expect(updated.colorValue, 0xFF03DAC6);
      expect(updated.name, 'Me');
    });

    test('two actors with same properties should be equal', () {
      const actor1 = Actor(id: 'actor-1', name: 'Me', colorValue: 0xFF6200EE);
      const actor2 = Actor(id: 'actor-1', name: 'Me', colorValue: 0xFF6200EE);

      expect(actor1, actor2);
    });

    test('two actors with different properties should not be equal', () {
      const actor1 = Actor(id: 'actor-1', name: 'Me', colorValue: 0xFF6200EE);
      const actor2 =
          Actor(id: 'actor-2', name: 'Alice', colorValue: 0xFF03DAC6);

      expect(actor1, isNot(actor2));
    });
  });
}
