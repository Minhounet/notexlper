/// Application-wide constants
class AppConstants {
  AppConstants._();

  static const String appName = 'NOTEXLPER';
  static const String appVersion = '1.0.0';

  /// Environment configuration
  /// Set via --dart-define=ENV=dev|prod
  static const String environment = String.fromEnvironment(
    'ENV',
    defaultValue: 'dev',
  );

  static bool get isDev => environment == 'dev';
  static bool get isProd => environment == 'prod';
}
