import 'package:shared_preferences/shared_preferences.dart';

/// Persists auth session preferences on this device across app restarts.
class DeviceSessionService {
  DeviceSessionService._();

  static const String _actorIdKey = 'device_actor_id';
  static const String _rememberMeKey = 'remember_me';

  // ---------------------------------------------------------------------------
  // Actor ID
  // ---------------------------------------------------------------------------

  /// Returns the actor ID stored on this device, or null on first launch.
  static Future<String?> getActorId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_actorIdKey);
  }

  /// Persists [actorId] as the current device's actor.
  static Future<void> saveActorId(String actorId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_actorIdKey, actorId);
  }

  /// Removes the stored actor ID and remember-me flag (e.g., on logout).
  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_actorIdKey);
    await prefs.remove(_rememberMeKey);
  }

  // ---------------------------------------------------------------------------
  // Remember Me
  // ---------------------------------------------------------------------------

  /// Returns the stored remember-me preference. Defaults to [true] if not set.
  static Future<bool> getRememberMe() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_rememberMeKey) ?? true;
  }

  /// Persists the remember-me preference.
  static Future<void> saveRememberMe(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_rememberMeKey, value);
  }
}
