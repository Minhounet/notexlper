import 'package:flutter_test/flutter_test.dart';
import 'package:notexlper/data/datasources/local/fake_auth_datasource.dart';

void main() {
  late FakeAuthDataSource dataSource;

  setUp(() {
    dataSource = FakeAuthDataSource(delay: Duration.zero);
  });

  group('FakeAuthDataSource', () {
    group('signUp', () {
      test('creates a new user and returns an ID', () async {
        final id = await dataSource.signUp('alice', 'secret123');
        expect(id, isNotEmpty);
      });

      test('different users get different IDs', () async {
        final id1 = await dataSource.signUp('alice', 'pass1');
        final id2 = await dataSource.signUp('bob', 'pass2');
        expect(id1, isNot(equals(id2)));
      });

      test('throws if username already taken', () async {
        await dataSource.signUp('alice', 'pass1');
        expect(
          () => dataSource.signUp('alice', 'pass2'),
          throwsException,
        );
      });

      test('sets the current user after sign-up', () async {
        final id = await dataSource.signUp('alice', 'pass');
        final currentId = await dataSource.getCurrentUserId();
        expect(currentId, id);
      });
    });

    group('signIn', () {
      test('returns ID for valid credentials', () async {
        final signUpId = await dataSource.signUp('alice', 'pass');
        final signInId = await dataSource.signIn('alice', 'pass');
        expect(signInId, signUpId);
      });

      test('throws for wrong password', () async {
        await dataSource.signUp('alice', 'correct');
        expect(
          () => dataSource.signIn('alice', 'wrong'),
          throwsException,
        );
      });

      test('throws for unknown username', () async {
        expect(
          () => dataSource.signIn('nobody', 'pass'),
          throwsException,
        );
      });

      test('seeded default user "me" signs in with "password"', () async {
        final id = await dataSource.signIn('me', 'password');
        expect(id, 'actor-1');
      });
    });

    group('signOut', () {
      test('clears the current user', () async {
        await dataSource.signUp('alice', 'pass');
        await dataSource.signOut();
        final id = await dataSource.getCurrentUserId();
        expect(id, isNull);
      });
    });

    group('getCurrentUserId', () {
      test('returns null when no user is signed in', () async {
        final id = await dataSource.getCurrentUserId();
        expect(id, isNull);
      });

      test('returns the ID after sign-in', () async {
        final signUpId = await dataSource.signUp('alice', 'pass');
        await dataSource.signIn('alice', 'pass');
        final currentId = await dataSource.getCurrentUserId();
        expect(currentId, signUpId);
      });
    });

    group('clear', () {
      test('removes all users', () async {
        await dataSource.signUp('alice', 'pass');
        dataSource.clear();
        expect(
          () => dataSource.signIn('alice', 'pass'),
          throwsException,
        );
      });

      test('clears current user', () async {
        await dataSource.signUp('alice', 'pass');
        dataSource.clear();
        final id = await dataSource.getCurrentUserId();
        expect(id, isNull);
      });
    });
  });
}
