import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:uuid/uuid.dart';

import 'core/constants/app_constants.dart';
import 'data/services/device_session_service.dart';
import 'data/services/fake_notification_service.dart';
import 'data/services/local_notification_service.dart';
import 'domain/entities/actor.dart';
import 'domain/entities/workspace.dart';
import 'domain/services/notification_service.dart';
import 'presentation/pages/home_page.dart';
import 'presentation/pages/splash_page.dart';
import 'presentation/providers/actor_providers.dart';
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
// SplashWrapper — boots the session then navigates to Home.
//
// On first launch  : auto-creates an actor + workspace, saves the actor ID.
// On later launches: reads the saved actor ID and logs in silently.
// The login picker page is no longer in the main navigation flow.
// ---------------------------------------------------------------------------
class SplashWrapper extends ConsumerStatefulWidget {
  const SplashWrapper({super.key});

  @override
  ConsumerState<SplashWrapper> createState() => _SplashWrapperState();
}

class _SplashWrapperState extends ConsumerState<SplashWrapper> {
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    _boot();
  }

  /// Runs the minimum splash duration and session init in parallel,
  /// then navigates to the home screen.
  Future<void> _boot() async {
    await Future.wait([
      Future.delayed(const Duration(seconds: 2)),
      _initSession(),
    ]);
    if (mounted) setState(() => _ready = true);
  }

  /// Resolves (or creates) the actor for this device.
  Future<void> _initSession() async {
    final storedId = await DeviceSessionService.getActorId();

    if (storedId != null) {
      // Known device — try to restore the actor.
      final result =
          await ref.read(actorRepositoryProvider).getActorById(storedId);
      await result.fold(
        // Actor was deleted (e.g. DB reset) — provision a fresh one.
        (failure) async => _autoCreate(),
        (actor) async {
          ref.read(currentActorProvider.notifier).login(actor);
          ref
              .read(currentWorkspaceProvider.notifier)
              .loadForOwner(actor.id)
              .ignore();
        },
      );
      return;
    }

    // First launch on this device.
    if (AppConstants.isDev) {
      // Dev: auto-select the first seeded actor ("Me") for convenience.
      final allResult =
          await ref.read(actorRepositoryProvider).getAllActors();
      final actors = allResult.getOrElse(() => []);
      if (actors.isNotEmpty) {
        final actor = actors.first;
        await DeviceSessionService.saveActorId(actor.id);
        ref.read(currentActorProvider.notifier).login(actor);
        ref
            .read(currentWorkspaceProvider.notifier)
            .loadForOwner(actor.id)
            .ignore();
        return;
      }
    }

    // Prod (or dev with empty data): create a brand-new account.
    await _autoCreate();
  }

  /// Creates a new actor + workspace and saves the actor ID to the device.
  Future<void> _autoCreate() async {
    const uuid = Uuid();
    final actor = Actor(
      id: uuid.v4(),
      name: 'My Account',
      colorValue: 0xFF6200EE,
    );

    final actorResult =
        await ref.read(actorRepositoryProvider).createActor(actor);

    await actorResult.fold(
      (failure) async {
        debugPrint('Auto-create actor failed: ${failure.message}');
      },
      (created) async {
        await DeviceSessionService.saveActorId(created.id);
        ref.read(currentActorProvider.notifier).login(created);

        final workspace = Workspace(
          id: uuid.v4(),
          name: 'My Workspace',
          ownerId: created.id,
          memberIds: [created.id],
        );
        final wsResult = await ref
            .read(currentWorkspaceProvider.notifier)
            .createWorkspace(workspace);
        wsResult.fold(
          (failure) =>
              debugPrint('Auto-create workspace failed: ${failure.message}'),
          (_) {},
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // SplashPage is purely visual; navigation is driven by _ready.
    return _ready ? const HomePage() : const SplashPage();
  }
}

