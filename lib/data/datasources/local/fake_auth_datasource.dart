import 'package:uuid/uuid.dart';

import '../auth_datasource.dart';

/// Fake in-memory auth data source for development and testing.
///
/// Seeds a default user "me" / "password" with actor ID "actor-1" so that
/// "remember me" works across app restarts in dev (FakeActorDataSource also
/// seeds actor-1 with the same ID).
class FakeAuthDataSource implements AuthDataSource {
  /// username → password
  final Map<String, String> _passwords = {};

  /// username → user ID
  final Map<String, String> _userIds = {};

  String? _currentUserId;

  final Duration delay;

  FakeAuthDataSource({this.delay = const Duration(milliseconds: 100)}) {
    _seedDefault();
  }

  void _seedDefault() {
    _passwords['me'] = 'password';
    _userIds['me'] = 'actor-1';
  }

  Future<void> _simulateDelay() async {
    if (delay > Duration.zero) await Future.delayed(delay);
  }

  @override
  Future<String> signUp(String username, String password) async {
    await _simulateDelay();
    if (_passwords.containsKey(username)) {
      throw Exception('Username "$username" is already taken');
    }
    final id = const Uuid().v4();
    _passwords[username] = password;
    _userIds[username] = id;
    _currentUserId = id;
    return id;
  }

  @override
  Future<String> signIn(String username, String password) async {
    await _simulateDelay();
    if (_passwords[username] != password) {
      throw Exception('Invalid username or password');
    }
    _currentUserId = _userIds[username];
    return _currentUserId!;
  }

  @override
  Future<void> signOut() async {
    await _simulateDelay();
    _currentUserId = null;
  }

  @override
  Future<String?> getCurrentUserId() async {
    return _currentUserId;
  }

  /// Clears all users (useful in tests).
  void clear() {
    _passwords.clear();
    _userIds.clear();
    _currentUserId = null;
  }
}
