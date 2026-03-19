import 'package:dartz/dartz.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../core/constants/app_constants.dart';
import '../../core/error/failures.dart';
import '../../core/utils/auth_debug_log.dart';
import '../../data/datasources/auth_datasource.dart';
import '../../data/datasources/local/fake_auth_datasource.dart';
import '../../data/datasources/remote/supabase_auth_datasource.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../data/services/device_session_service.dart';
import '../../domain/entities/actor.dart';
import '../../domain/entities/workspace.dart';
import '../../domain/repositories/auth_repository.dart';
import 'actor_providers.dart';
import 'workspace_providers.dart';

/// Streams the auth debug log lines to the UI.
final authDebugLogProvider = StreamProvider<List<String>>((ref) async* {
  yield AuthDebugLog.lines; // current buffer immediately
  yield* AuthDebugLog.stream; // then live updates
});

/// Predefined avatar colours for auto-assignment on account creation.
const _kAvatarColors = [
  0xFF6200EE, // deep purple
  0xFF03DAC6, // teal
  0xFFE91E63, // pink
  0xFF2196F3, // blue
  0xFF4CAF50, // green
  0xFFFF9800, // orange
];

int _colorForUsername(String username) {
  final index =
      username.codeUnits.fold(0, (a, b) => a + b) % _kAvatarColors.length;
  return _kAvatarColors[index];
}

/// Provides the auth data source (fake in dev, Supabase in prod).
final authDataSourceProvider = Provider<AuthDataSource>((ref) {
  if (AppConstants.isProd) {
    return SupabaseAuthDataSource(Supabase.instance.client);
  }
  return FakeAuthDataSource();
});

/// Provides the auth repository.
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepositoryImpl(dataSource: ref.watch(authDataSourceProvider));
});

// ---------------------------------------------------------------------------
// AuthNotifier — drives sign-up and sign-in flows from the UI.
// ---------------------------------------------------------------------------

class AuthNotifier extends StateNotifier<AsyncValue<void>> {
  final AuthRepository _authRepo;
  final Ref _ref;

  AuthNotifier(this._authRepo, this._ref) : super(const AsyncValue.data(null));

  /// Creates a new account, then auto-creates an actor and workspace.
  Future<Either<Failure, void>> signUp(
    String username,
    String password,
    bool rememberMe,
  ) async {
    AuthDebugLog.add('signUp: attempting for username="$username" '
        'env=${AppConstants.environment}');
    state = const AsyncValue.loading();
    final authResult = await _authRepo.signUp(username, password);

    if (authResult.isLeft()) {
      final failure = authResult.swap().getOrElse(() => const AuthFailure());
      AuthDebugLog.add('signUp: FAILED — ${failure.message}');
      state = AsyncValue.error(failure.message, StackTrace.current);
      return Left(failure);
    }

    final userId = authResult.getOrElse(() => '');
    AuthDebugLog.add('signUp: auth OK, userId=$userId — creating actor…');
    return _postAuthSetup(
        userId: userId, username: username, rememberMe: rememberMe);
  }

  /// Signs into an existing account.
  Future<Either<Failure, void>> signIn(
    String username,
    String password,
    bool rememberMe,
  ) async {
    AuthDebugLog.add('signIn: attempting for username="$username" '
        'env=${AppConstants.environment}');
    state = const AsyncValue.loading();
    final authResult = await _authRepo.signIn(username, password);

    if (authResult.isLeft()) {
      final failure = authResult.swap().getOrElse(() => const AuthFailure());
      AuthDebugLog.add('signIn: FAILED — ${failure.message}');
      state = AsyncValue.error(failure.message, StackTrace.current);
      return Left(failure);
    }

    final userId = authResult.getOrElse(() => '');
    AuthDebugLog.add('signIn: auth OK, userId=$userId — loading actor…');
    final actorResult =
        await _ref.read(actorRepositoryProvider).getActorById(userId);

    if (actorResult.isLeft()) {
      final failure = actorResult.swap().getOrElse(() => const AuthFailure());
      AuthDebugLog.add('signIn: actor load FAILED — ${failure.message}');
      state = AsyncValue.error(failure.message, StackTrace.current);
      return Left(failure);
    }

    final actor = actorResult.getOrElse(
      () => throw StateError('actor must exist at this point'),
    );
    AuthDebugLog.add('signIn: success — actor="${actor.name}"');
    await _finalizeSession(actor, rememberMe, loadWorkspace: true);
    return const Right(null);
  }

  /// Signs out and clears the session.
  Future<void> signOut() async {
    await _authRepo.signOut();
    await DeviceSessionService.clear();
    _ref.read(currentActorProvider.notifier).logout();
    _ref.read(currentWorkspaceProvider.notifier).clear();
    state = const AsyncValue.data(null);
  }

  // ---------------------------------------------------------------------------
  // Internals
  // ---------------------------------------------------------------------------

  Future<Either<Failure, void>> _postAuthSetup({
    required String userId,
    required String username,
    required bool rememberMe,
  }) async {
    final actor = Actor(
      id: userId,
      name: username,
      colorValue: _colorForUsername(username),
    );

    final actorResult =
        await _ref.read(actorListProvider.notifier).createActor(actor);

    if (actorResult.isLeft()) {
      final failure = actorResult.swap().getOrElse(() => const AuthFailure());
      AuthDebugLog.add('signUp: actor creation FAILED — ${failure.message}');
      state = AsyncValue.error(failure.message, StackTrace.current);
      return Left(failure);
    }

    final createdActor = actorResult.getOrElse(
      () => throw StateError('actor must exist at this point'),
    );
    AuthDebugLog.add('signUp: actor created — id=${createdActor.id}');

    // Auto-create workspace.
    final workspace = Workspace(
      id: const Uuid().v4(),
      name: "${createdActor.name}'s Workspace",
      ownerId: createdActor.id,
      memberIds: [createdActor.id],
    );
    final wsResult = await _ref
        .read(currentWorkspaceProvider.notifier)
        .createWorkspace(workspace);

    wsResult.fold(
      (failure) {
        AuthDebugLog.add('signUp: workspace creation FAILED — ${failure.message}');
        debugPrint('Workspace creation failed: ${failure.message}');
      },
      (_) => AuthDebugLog.add('signUp: workspace created — all done'),
    );

    await _finalizeSession(createdActor, rememberMe, loadWorkspace: false);
    return const Right(null);
  }

  Future<void> _finalizeSession(
    Actor actor,
    bool rememberMe, {
    required bool loadWorkspace,
  }) async {
    await DeviceSessionService.saveActorId(actor.id);
    await DeviceSessionService.saveRememberMe(rememberMe);
    _ref.read(currentActorProvider.notifier).login(actor);
    if (loadWorkspace) {
      _ref
          .read(currentWorkspaceProvider.notifier)
          .loadForOwner(actor.id)
          .ignore();
    }
    state = const AsyncValue.data(null);
  }
}

/// Provider for [AuthNotifier].
final authProvider =
    StateNotifierProvider<AuthNotifier, AsyncValue<void>>((ref) {
  return AuthNotifier(ref.watch(authRepositoryProvider), ref);
});
