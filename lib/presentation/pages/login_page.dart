import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/actor.dart';
import '../providers/actor_providers.dart';

/// Login page where the user picks which actor to log in as.
class LoginPage extends ConsumerWidget {
  final VoidCallback onLoggedIn;

  const LoginPage({super.key, required this.onLoggedIn});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final actorsAsync = ref.watch(actorListProvider);
    final theme = Theme.of(context);

    return Scaffold(
      body: Center(
        child: actorsAsync.when(
          loading: () => const CircularProgressIndicator(),
          error: (error, _) => Text('Error: $error'),
          data: (actors) => Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.people_outline,
                  size: 80,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(height: 24),
                Text(
                  'Who are you?',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Select your profile to enter the workspace',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 32),
                ...actors.map((actor) => _ActorLoginTile(
                      actor: actor,
                      onTap: () {
                        ref.read(currentActorProvider.notifier).login(actor);
                        onLoggedIn();
                      },
                    )),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ActorLoginTile extends StatelessWidget {
  final Actor actor;
  final VoidCallback onTap;

  const _ActorLoginTile({required this.actor, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: Color(actor.colorValue),
                  child: Text(
                    actor.name[0].toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    actor.name,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
