import 'package:dartz/dartz.dart';

import '../../core/error/failures.dart';

/// Abstract repository for authentication operations.
///
/// Returns the auth user ID (a UUID) on success.
/// In dev mode, the fake implementation uses in-memory credentials.
/// In prod, Supabase Auth handles the actual authentication.
abstract class AuthRepository {
  /// Creates a new account with [username] and [password].
  /// Returns the new user's ID on success.
  Future<Either<Failure, String>> signUp(String username, String password);

  /// Signs in with [username] and [password].
  /// Returns the user's ID on success.
  Future<Either<Failure, String>> signIn(String username, String password);

  /// Signs out the current user.
  Future<Either<Failure, void>> signOut();

  /// Returns the current signed-in user's ID, or null if not signed in.
  Future<String?> getCurrentUserId();
}
