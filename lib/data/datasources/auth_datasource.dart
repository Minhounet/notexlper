/// Abstract data source interface for authentication.
///
/// Throws exceptions on failure (repository wraps them into [Failure]s).
abstract class AuthDataSource {
  /// Creates a new user with [username] and [password].
  /// Returns the new user's ID.
  /// Throws if the username is already taken.
  Future<String> signUp(String username, String password);

  /// Signs in with [username] and [password].
  /// Returns the user's ID.
  /// Throws if credentials are invalid.
  Future<String> signIn(String username, String password);

  /// Signs out the current user.
  Future<void> signOut();

  /// Returns the current user's ID, or null if not signed in.
  Future<String?> getCurrentUserId();
}
