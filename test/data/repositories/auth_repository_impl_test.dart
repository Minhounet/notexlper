import 'package:flutter_test/flutter_test.dart';
import 'package:notexlper/core/error/failures.dart';
import 'package:notexlper/data/datasources/local/fake_auth_datasource.dart';
import 'package:notexlper/data/repositories/auth_repository_impl.dart';

void main() {
  late FakeAuthDataSource dataSource;
  late AuthRepositoryImpl repository;

  setUp(() {
    dataSource = FakeAuthDataSource(delay: Duration.zero);
    repository = AuthRepositoryImpl(dataSource: dataSource);
  });

  group('AuthRepositoryImpl', () {
    group('signUp', () {
      test('returns Right(userId) on success', () async {
        final result = await repository.signUp('alice', 'pass123');

        expect(result.isRight(), true);
        result.fold(
          (f) => fail('Expected Right'),
          (id) => expect(id, isNotEmpty),
        );
      });

      test('returns Left(AuthFailure) when username is taken', () async {
        await repository.signUp('alice', 'pass1');
        final result = await repository.signUp('alice', 'pass2');

        expect(result.isLeft(), true);
        result.fold(
          (failure) => expect(failure, isA<AuthFailure>()),
          (_) => fail('Expected Left'),
        );
      });
    });

    group('signIn', () {
      test('returns Right(userId) for valid credentials', () async {
        final signUpResult = await repository.signUp('alice', 'pass123');
        final expectedId = signUpResult.getOrElse(() => '');

        final result = await repository.signIn('alice', 'pass123');

        expect(result.isRight(), true);
        result.fold(
          (f) => fail('Expected Right'),
          (id) => expect(id, expectedId),
        );
      });

      test('returns Left(AuthFailure) for wrong password', () async {
        await repository.signUp('alice', 'correct');
        final result = await repository.signIn('alice', 'wrong');

        expect(result.isLeft(), true);
        result.fold(
          (failure) => expect(failure, isA<AuthFailure>()),
          (_) => fail('Expected Left'),
        );
      });

      test('returns Left(AuthFailure) for unknown user', () async {
        final result = await repository.signIn('nobody', 'pass');

        expect(result.isLeft(), true);
        result.fold(
          (failure) => expect(failure, isA<AuthFailure>()),
          (_) => fail('Expected Left'),
        );
      });
    });

    group('signOut', () {
      test('returns Right on success', () async {
        await repository.signUp('alice', 'pass');
        final result = await repository.signOut();

        expect(result.isRight(), true);
      });

      test('clears current user', () async {
        await repository.signUp('alice', 'pass');
        await repository.signOut();
        final userId = await repository.getCurrentUserId();
        expect(userId, isNull);
      });
    });

    group('getCurrentUserId', () {
      test('returns null when not signed in', () async {
        final id = await repository.getCurrentUserId();
        expect(id, isNull);
      });

      test('returns userId after sign-in', () async {
        final signUpResult = await repository.signUp('alice', 'pass');
        final expected = signUpResult.getOrElse(() => '');

        await repository.signIn('alice', 'pass');
        final id = await repository.getCurrentUserId();
        expect(id, expected);
      });
    });
  });
}
