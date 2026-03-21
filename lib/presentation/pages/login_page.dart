import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../core/utils/auth_debug_log.dart';
import '../../domain/entities/actor.dart';
import '../../domain/entities/workspace.dart';
import '../providers/actor_providers.dart';
import '../providers/workspace_providers.dart';

/// Predefined avatar colours for account creation.
const _kAvatarColors = [
  Color(0xFF6200EE), // deep purple
  Color(0xFF03DAC6), // teal
  Color(0xFFE91E63), // pink
  Color(0xFF2196F3), // blue
  Color(0xFF4CAF50), // green
  Color(0xFFFF9800), // orange
];

/// Login page: lets existing actors sign in, or creates a new account.
class LoginPage extends ConsumerStatefulWidget {
  final VoidCallback onLoggedIn;

  const LoginPage({super.key, required this.onLoggedIn});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  bool _showCreateForm = false;

  void _toggleCreateForm() =>
      setState(() => _showCreateForm = !_showCreateForm);

  void _loginAs(Actor actor) {
    AuthDebugLog.add('LoginPage: signing in as "${actor.name}" (id=${actor.id})');
    ref.read(currentActorProvider.notifier).login(actor);
    // Workspace loads in the background; the home page reacts via Riverpod.
    ref
        .read(currentWorkspaceProvider.notifier)
        .loadForOwner(actor.id)
        .ignore();
    AuthDebugLog.add('LoginPage: login complete, navigating to home');
    widget.onLoggedIn();
  }

  @override
  Widget build(BuildContext context) {
    final actorsAsync = ref.watch(actorListProvider);
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(32),
            child: actorsAsync.when(
              loading: () => const CircularProgressIndicator(),
              error: (error, _) => Text('Error: $error'),
              data: (actors) => Column(
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
                    'Select your profile or create a new account',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  // Existing actor tiles
                  ...actors.map(
                    (actor) => _ActorLoginTile(
                      actor: actor,
                      onTap: () => _loginAs(actor),
                    ),
                  ),
                  if (actors.isNotEmpty) const SizedBox(height: 12),
                  // Create account section
                  if (_showCreateForm)
                    _CreateAccountForm(
                      onCreated: (actor) async {
                        setState(() => _showCreateForm = false);
                        _loginAs(actor);
                      },
                      onCancel: actors.isNotEmpty ? _toggleCreateForm : null,
                    )
                  else
                    OutlinedButton.icon(
                      onPressed: _toggleCreateForm,
                      icon: const Icon(Icons.person_add_outlined),
                      label: const Text('Create new account'),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Existing actor tile
// ---------------------------------------------------------------------------

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

// ---------------------------------------------------------------------------
// Create-account form
// ---------------------------------------------------------------------------

class _CreateAccountForm extends ConsumerStatefulWidget {
  final Future<void> Function(Actor actor) onCreated;
  final VoidCallback? onCancel;

  const _CreateAccountForm({required this.onCreated, this.onCancel});

  @override
  ConsumerState<_CreateAccountForm> createState() => _CreateAccountFormState();
}

class _CreateAccountFormState extends ConsumerState<_CreateAccountForm> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  int _selectedColorIndex = 0;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    const uuid = Uuid();
    final actorId = uuid.v4();
    final name = _nameController.text.trim();
    final actor = Actor(
      id: actorId,
      name: name,
      colorValue: _kAvatarColors[_selectedColorIndex].value,
    );

    AuthDebugLog.add(
      'LoginPage: creating account name="$name" id=$actorId '
      'color=#${actor.colorValue.toRadixString(16).padLeft(8, '0')}',
    );

    // 1. Create the actor.
    final actorResult =
        await ref.read(actorListProvider.notifier).createActor(actor);

    if (!mounted) return;

    await actorResult.fold(
      (failure) async {
        AuthDebugLog.add(
          'LoginPage: account creation FAILED — ${failure.message}',
        );
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Failed to create account: ${failure.message}')),
        );
      },
      (createdActor) async {
        AuthDebugLog.add(
          'LoginPage: account created successfully for "${createdActor.name}" (id=${createdActor.id})',
        );

        // 2. Auto-create a personal workspace.
        final workspaceId = uuid.v4();
        final workspace = Workspace(
          id: workspaceId,
          name: "${createdActor.name}'s Workspace",
          ownerId: createdActor.id,
          memberIds: [createdActor.id],
        );
        AuthDebugLog.add(
          'LoginPage: creating workspace "${workspace.name}" (id=$workspaceId) '
          'for owner=${createdActor.id}',
        );
        final wsResult = await ref
            .read(currentWorkspaceProvider.notifier)
            .createWorkspace(workspace);

        if (!mounted) return;

        wsResult.fold(
          (failure) {
            // Non-fatal: workspace creation failed, log and continue.
            AuthDebugLog.add(
              'LoginPage: workspace creation FAILED — ${failure.message}',
            );
            debugPrint('Workspace creation failed: ${failure.message}');
          },
          (_) {
            AuthDebugLog.add(
              'LoginPage: workspace created successfully (id=$workspaceId)',
            );
          },
        );

        setState(() => _isLoading = false);
        await widget.onCreated(createdActor);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Create your account',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Your name',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person_outline),
                ),
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) => _submit(),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter your name';
                  }
                  if (value.trim().length > 50) {
                    return 'Name is too long';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              Text(
                'Pick a colour',
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 8),
              Row(
                children: List.generate(_kAvatarColors.length, (i) {
                  final selected = i == _selectedColorIndex;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedColorIndex = i),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: _kAvatarColors[i],
                          shape: BoxShape.circle,
                          border: selected
                              ? Border.all(
                                  color: theme.colorScheme.onSurface,
                                  width: 3,
                                )
                              : null,
                        ),
                        child: selected
                            ? const Icon(Icons.check,
                                color: Colors.white, size: 18)
                            : null,
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  if (widget.onCancel != null) ...[
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _isLoading ? null : widget.onCancel,
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],
                  Expanded(
                    child: FilledButton(
                      onPressed: _isLoading ? null : _submit,
                      child: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child:
                                  CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Create account'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
