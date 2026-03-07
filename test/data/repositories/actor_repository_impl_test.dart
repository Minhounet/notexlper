import 'package:flutter_test/flutter_test.dart';
import 'package:notexlper/data/datasources/local/fake_actor_datasource.dart';
import 'package:notexlper/data/repositories/actor_repository_impl.dart';
import 'package:notexlper/domain/entities/actor.dart';

void main() {
  late FakeActorDataSource dataSource;
  late ActorRepositoryImpl repository;

  setUp(() {
    dataSource = FakeActorDataSource();
    repository = ActorRepositoryImpl(dataSource: dataSource);
  });

  group('ActorRepositoryImpl', () {
    group('getAllActors', () {
      test('should return seeded actors', () async {
        final result = await repository.getAllActors();

        expect(result.isRight(), true);
        result.fold(
          (failure) => fail('Should not return failure'),
          (actors) {
            expect(actors.length, 2);
            expect(actors[0].name, 'Me');
            expect(actors[1].name, 'Alice');
          },
        );
      });

      test('should return empty list after clear', () async {
        dataSource.clear();
        final result = await repository.getAllActors();

        expect(result.isRight(), true);
        result.fold(
          (failure) => fail('Should not return failure'),
          (actors) => expect(actors, isEmpty),
        );
      });
    });

    group('getActorById', () {
      test('should return actor when it exists', () async {
        final result = await repository.getActorById('actor-1');

        expect(result.isRight(), true);
        result.fold(
          (failure) => fail('Should not return failure'),
          (actor) {
            expect(actor.id, 'actor-1');
            expect(actor.name, 'Me');
          },
        );
      });

      test('should return NotFoundFailure when actor does not exist', () async {
        final result = await repository.getActorById('non-existent');

        expect(result.isLeft(), true);
      });
    });

    group('createActor', () {
      test('should persist and return the new actor', () async {
        const newActor = Actor(
          id: 'actor-99',
          name: 'Bob',
          colorValue: 0xFF2196F3,
        );

        final result = await repository.createActor(newActor);

        expect(result.isRight(), true);
        result.fold(
          (failure) => fail('Should not return failure'),
          (actor) {
            expect(actor.id, 'actor-99');
            expect(actor.name, 'Bob');
          },
        );
      });

      test('created actor should be retrievable by id', () async {
        const newActor = Actor(
          id: 'actor-99',
          name: 'Bob',
          colorValue: 0xFF2196F3,
        );

        await repository.createActor(newActor);
        final result = await repository.getActorById('actor-99');

        expect(result.isRight(), true);
        result.fold(
          (failure) => fail('Should not return failure'),
          (actor) => expect(actor.name, 'Bob'),
        );
      });

      test('created actor appears in getAllActors', () async {
        const newActor = Actor(
          id: 'actor-99',
          name: 'Bob',
          colorValue: 0xFF2196F3,
        );

        await repository.createActor(newActor);
        final result = await repository.getAllActors();

        expect(result.isRight(), true);
        result.fold(
          (failure) => fail('Should not return failure'),
          (actors) {
            expect(actors.any((a) => a.id == 'actor-99'), true);
          },
        );
      });
    });
  });
}
