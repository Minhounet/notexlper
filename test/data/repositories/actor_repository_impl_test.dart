import 'package:flutter_test/flutter_test.dart';
import 'package:notexlper/data/datasources/local/fake_actor_datasource.dart';
import 'package:notexlper/data/repositories/actor_repository_impl.dart';

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
  });
}
