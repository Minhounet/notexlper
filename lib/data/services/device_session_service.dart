import 'package:shared_preferences/shared_preferences.dart';

/// Persists the current device's actor ID across app restarts.
///
/// This lets the app auto-login on subsequent launches without showing
/// the login screen. The stored ID is cleared if the user explicitly logs out.
class DeviceSessionService {
  DeviceSessionService._();

  static const String _key = 'device_actor_id';

  /// Returns the actor ID stored on this device, or null on first launch.
  static Future<String?> getActorId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_key);
  }

  /// Persists [actorId] as the current device's actor.
  static Future<void> saveActorId(String actorId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, actorId);
  }

  /// Removes the stored actor ID (e.g., on logout).
  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
