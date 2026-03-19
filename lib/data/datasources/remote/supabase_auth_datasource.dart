import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../auth_datasource.dart';

/// Supabase implementation of [AuthDataSource].
///
/// Usernames are stored in Supabase Auth user metadata.
/// Internally, Supabase requires an email, so we derive one as
/// `{username}@notexlper.local`. Users only ever see/type "username".
class SupabaseAuthDataSource implements AuthDataSource {
  final SupabaseClient _client;

  SupabaseAuthDataSource(this._client);

  String _toEmail(String username) => '$username@notexlper.local';

  @override
  Future<String> signUp(String username, String password) async {
    debugPrint('[SupabaseAuth] signUp called for username="$username" '
        'email="${_toEmail(username)}"');
    try {
      final response = await _client.auth.signUp(
        email: _toEmail(username),
        password: password,
        data: {'username': username},
      );
      final user = response.user;
      if (user == null) throw Exception('Sign up failed: no user returned');
      debugPrint('[SupabaseAuth] signUp success, userId=${user.id}');
      return user.id;
    } on AuthException catch (e, st) {
      debugPrint('[SupabaseAuth] signUp AuthException: ${e.message} '
          '(status=${e.statusCode})\n$st');
      rethrow;
    } catch (e, st) {
      debugPrint('[SupabaseAuth] signUp unexpected error: $e\n$st');
      rethrow;
    }
  }

  @override
  Future<String> signIn(String username, String password) async {
    debugPrint('[SupabaseAuth] signIn called for username="$username"');
    try {
      final response = await _client.auth.signInWithPassword(
        email: _toEmail(username),
        password: password,
      );
      final user = response.user;
      if (user == null) throw Exception('Sign in failed: no user returned');
      debugPrint('[SupabaseAuth] signIn success, userId=${user.id}');
      return user.id;
    } on AuthException catch (e, st) {
      debugPrint('[SupabaseAuth] signIn AuthException: ${e.message} '
          '(status=${e.statusCode})\n$st');
      rethrow;
    } catch (e, st) {
      debugPrint('[SupabaseAuth] signIn unexpected error: $e\n$st');
      rethrow;
    }
  }

  @override
  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  @override
  Future<String?> getCurrentUserId() async {
    return _client.auth.currentUser?.id;
  }
}
