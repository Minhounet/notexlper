import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/constants/app_constants.dart';
import 'presentation/pages/home_page.dart';
import 'presentation/pages/login_page.dart';
import 'presentation/pages/splash_page.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ProviderScope(child: NotexlperApp()));
}

class NotexlperApp extends StatelessWidget {
  const NotexlperApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      themeMode: ThemeMode.system,
      home: const SplashWrapper(),
    );
  }
}

enum _AppPhase { splash, login, home }

class SplashWrapper extends StatefulWidget {
  const SplashWrapper({super.key});

  @override
  State<SplashWrapper> createState() => _SplashWrapperState();
}

class _SplashWrapperState extends State<SplashWrapper> {
  _AppPhase _phase = _AppPhase.splash;

  @override
  Widget build(BuildContext context) {
    switch (_phase) {
      case _AppPhase.splash:
        return SplashPage(
          onInitialized: () => setState(() => _phase = _AppPhase.login),
        );
      case _AppPhase.login:
        return LoginPage(
          onLoggedIn: () => setState(() => _phase = _AppPhase.home),
        );
      case _AppPhase.home:
        return const HomePage();
    }
  }
}
