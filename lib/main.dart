import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import 'core/constants/app_constants.dart';
import 'data/services/device_session_service.dart';
import 'data/services/fake_notification_service.dart';
import 'data/services/local_notification_service.dart';
import 'domain/services/notification_service.dart';
import 'presentation/pages/auth_page.dart';
import 'presentation/pages/home_page.dart';
import 'presentation/pages/splash_page.dart';
import 'presentation/providers/actor_providers.dart';
import 'presentation/providers/auth_providers.dart';
import 'presentation/providers/notification_providers.dart';
import 'presentation/providers/workspace_providers.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final NotificationService notificationService;

  if (AppConstants.isProd) {
    // Connect to Supabase.
    await Supabase.initialize(
      url: AppConstants.supabaseUrl,
      anonKey: AppConstants.supabaseAnonKey,
    );

    // Real notification service: initialize timezone and platform plugin.
    tz.initializeTimeZones();
    final deviceTimeZone = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(deviceTimeZone));
    notificationService = await LocalNotificationService.init();
  } else {
    // Dev mode: use fake service — no platform calls, no permission dialogs.
    notificationService = FakeNotificationService();
  }

  runApp(
    ProviderScope(
      overrides: [
        notificationServiceProvider.overrideWithValue(notificationService),
      ],
      child: const NotexlperApp(),
    ),
  );
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

// ---------------------------------------------------------------------------
// SplashWrapper — boots the session then navigates to Home or AuthPage.
//
// Decision tree:
//   1. Check remember_me + stored actor ID in SharedPreferences.
//   2. If both present:
//      - Prod: also verify Supabase session is still valid.
//      - Try to restore actor from repository.
//      - Success → HomePage.
//   3. Otherwise → AuthPage (first launch shows "Create Account" tab).
// ---------------------------------------------------------------------------
class SplashWrapper extends ConsumerStatefulWidget {
  const SplashWrapper({super.key});

  @override
  ConsumerState<SplashWrapper> createState() => _SplashWrapperState();
}

class _SplashWrapperState extends ConsumerState<SplashWrapper> {
  bool _ready = false;
  bool _needsAuth = true;

  @override
  void initState() {
    super.initState();
    _boot();
  }

  Future<void> _boot() async {
    await Future.wait([
      Future.delayed(const Duration(seconds: 2)),
      _initSession(),
    ]);
    if (mounted) setState(() => _ready = true);
  }

  /// Checks for a stored session and restores it, or sets [_needsAuth] = true.
  Future<void> _initSession() async {
    final rememberMe = await DeviceSessionService.getRememberMe();
    final storedActorId = await DeviceSessionService.getActorId();

    if (storedActorId == null || !rememberMe) {
      _needsAuth = true;
      return;
    }

    // In prod, also verify the Supabase session is still alive.
    if (AppConstants.isProd) {
      final userId =
          await ref.read(authRepositoryProvider).getCurrentUserId();
      if (userId == null) {
        _needsAuth = true;
        return;
      }
    }

    // Try to restore the actor from the repository.
    final result =
        await ref.read(actorRepositoryProvider).getActorById(storedActorId);
    result.fold(
      (failure) {
        // Actor was deleted or DB was reset — require re-login.
        _needsAuth = true;
      },
      (actor) {
        ref.read(currentActorProvider.notifier).login(actor);
        ref
            .read(currentWorkspaceProvider.notifier)
            .loadForOwner(actor.id)
            .ignore();
        _needsAuth = false;
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_ready) return const SplashPage();
    if (_needsAuth) {
      return AuthPage(
        onAuthenticated: () => setState(() => _needsAuth = false),
      );
    }
    return const HomePage();
  }
}
