/// Application-wide constants
class AppConstants {
  AppConstants._();

  static const String appName = 'NOTEXLPER';
  static const String appVersion = '1.0.0';

  // Supabase — anon key is intentionally public (security enforced via RLS).
  static const String supabaseUrl = 'https://vykxobvkzmjvbdwdpozn.supabase.co';
  static const String supabaseAnonKey =
      'sb_publishable_VjDQ4cptK8TdLIuu8pao9g_i_zqVbzB';

  /// Environment configuration
  /// Set via --dart-define=ENV=dev|prod
  static const String environment = String.fromEnvironment(
    'ENV',
    defaultValue: 'dev',
  );

  static bool get isDev => environment == 'dev';
  static bool get isProd => environment == 'prod';
}
