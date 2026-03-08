import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../core/constants/app_constants.dart';
import '../../core/logging/app_logger.dart' show AppLogger, LogNotifier;
import 'log_viewer_page.dart';
import '../../domain/entities/actor.dart';
import '../../domain/entities/checklist_item.dart';
import '../../domain/entities/checklist_note.dart';
import '../../domain/entities/workspace.dart';
import '../providers/actor_providers.dart';
import '../providers/category_providers.dart';
import '../providers/checklist_providers.dart';
import '../providers/workspace_providers.dart';
import '../widgets/checklist_card.dart';
import 'category_admin_page.dart';
import 'checklist_detail_page.dart';

/// Predefined avatar colours reused from login page constants.
const _kAvatarColors = [
  Color(0xFF6200EE),
  Color(0xFF03DAC6),
  Color(0xFFE91E63),
  Color(0xFF2196F3),
  Color(0xFF4CAF50),
  Color(0xFFFF9800),
];

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notesAsync = ref.watch(checklistListProvider);
    final categoriesAsync = ref.watch(categoryListProvider);
    final currentActor = ref.watch(currentActorProvider);
    final actorsAsync = ref.watch(actorListProvider);
    final workspaceAsync = ref.watch(currentWorkspaceProvider);
    final workspace = workspaceAsync.valueOrNull;

    return Scaffold(
      appBar: AppBar(
        leading: currentActor != null
            ? Padding(
                padding: const EdgeInsets.all(8.0),
                child: GestureDetector(
                  onTap: () => _showSwitchActorDialog(context, ref),
                  child: CircleAvatar(
                    backgroundColor: Color(currentActor.colorValue),
                    child: Text(
                      currentActor.name[0].toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              )
            : null,
        title: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              workspace?.name ?? AppConstants.appName,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            if (AppConstants.isDev)
              Container(
                margin: const EdgeInsets.only(top: 2),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(
                  color: Colors.orange,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'DEV',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
              ),
          ],
        ),
        centerTitle: true,
        actions: [
          ListenableBuilder(
            listenable: LogNotifier.instance,
            builder: (context, _) {
              final hasErrors =
                  AppLogger.instance.entries.any((e) => e.error != null);
              return IconButton(
                icon: Badge(
                  isLabelVisible: hasErrors,
                  child: const Icon(Icons.bug_report_outlined),
                ),
                tooltip: 'View logs',
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const LogViewerPage(),
                  ),
                ),
              );
            },
          ),
          if (workspace != null)
            IconButton(
              icon: const Icon(Icons.person_add_outlined),
              onPressed: () => _showInviteDialog(context, workspace),
              tooltip: 'Invite collaborator',
            ),
          IconButton(
            icon: const Icon(Icons.label_outline),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const CategoryAdminPage(),
                ),
              );
            },
            tooltip: 'Manage Categories',
          ),
        ],
      ),
      body: notesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48),
              const SizedBox(height: 16),
              Text('Error: $error'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () =>
                    ref.read(checklistListProvider.notifier).loadNotes(),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (notes) {
          final categories = categoriesAsync.valueOrNull ?? [];
          final actors = actorsAsync.valueOrNull ?? [];
          if (notes.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.checklist_rounded,
                    size: 80,
                    color:
                        Theme.of(context).colorScheme.primary.withOpacity(0.5),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No checklists yet',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color:
                              Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tap + to create your first checklist',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color:
                              Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: notes.length,
            itemBuilder: (context, index) {
              final note = notes[index];
              return ChecklistCard(
                note: note,
                categories: categories,
                actors: actors,
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _createNewChecklist(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('New Checklist'),
      ),
    );
  }

  Future<void> _showSwitchActorDialog(
      BuildContext context, WidgetRef ref) async {
    final actorsAsync = ref.read(actorListProvider);
    final actors = actorsAsync.valueOrNull ?? [];
    final currentActor = ref.read(currentActorProvider);

    final selected = await showDialog<Actor>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Switch user'),
        children: actors.map((actor) {
          final isCurrent = actor.id == currentActor?.id;
          return SimpleDialogOption(
            onPressed: () => Navigator.pop(context, actor),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: Color(actor.colorValue),
                  child: Text(
                    actor.name[0].toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(child: Text(actor.name)),
                if (isCurrent)
                  Icon(Icons.check,
                      color: Theme.of(context).colorScheme.primary),
              ],
            ),
          );
        }).toList(),
      ),
    );

    if (selected != null) {
      ref.read(currentActorProvider.notifier).login(selected);
      ref
          .read(currentWorkspaceProvider.notifier)
          .loadForOwner(selected.id)
          .ignore();
    }
  }

  Future<void> _showInviteDialog(
      BuildContext context, Workspace workspace) async {
    await showDialog<void>(
      context: context,
      builder: (context) => _InviteCollaboratorDialog(workspace: workspace),
    );
  }

  Future<void> _createNewChecklist(BuildContext context, WidgetRef ref) async {
    final now = DateTime.now();
    final currentActor = ref.read(currentActorProvider);
    final creatorId = currentActor?.id;

    final newNote = ChecklistNote(
      id: 'note-${now.millisecondsSinceEpoch}',
      title: '',
      items: [
        ChecklistItem(
          id: 'item-${now.millisecondsSinceEpoch}',
          text: '',
          order: 0,
        ),
      ],
      createdAt: now,
      updatedAt: now,
      creatorId: creatorId,
      assigneeIds: creatorId != null ? [creatorId] : [],
    );

    final repository = ref.read(checklistRepositoryProvider);
    await repository.createNote(newNote);
    await ref.read(checklistListProvider.notifier).loadNotes();

    if (context.mounted) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ChecklistDetailPage(note: newNote),
        ),
      );
    }
  }
}

// ---------------------------------------------------------------------------
// Invite collaborator dialog
// ---------------------------------------------------------------------------

class _InviteCollaboratorDialog extends ConsumerStatefulWidget {
  final Workspace workspace;

  const _InviteCollaboratorDialog({required this.workspace});

  @override
  ConsumerState<_InviteCollaboratorDialog> createState() =>
      _InviteCollaboratorDialogState();
}

class _InviteCollaboratorDialogState
    extends ConsumerState<_InviteCollaboratorDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  int _selectedColorIndex = 1;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _invite() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    const uuid = Uuid();
    final actor = Actor(
      id: uuid.v4(),
      name: _nameController.text.trim(),
      colorValue: _kAvatarColors[_selectedColorIndex].value,
    );

    // 1. Create the actor.
    final actorResult =
        await ref.read(actorListProvider.notifier).createActor(actor);

    if (!mounted) return;

    await actorResult.fold(
      (failure) async {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to add collaborator: ${failure.message}')),
        );
      },
      (createdActor) async {
        // 2. Add them to the workspace.
        final wsResult = await ref
            .read(currentWorkspaceProvider.notifier)
            .addMember(widget.workspace.id, createdActor.id);

        if (!mounted) return;

        setState(() => _isLoading = false);
        wsResult.fold(
          (failure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                  content: Text(
                      'Collaborator created but could not join workspace: ${failure.message}')),
            );
          },
          (_) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                  content: Text(
                      '${createdActor.name} added to your workspace!')),
            );
          },
        );
        Navigator.of(context).pop();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AlertDialog(
      title: const Text('Invite collaborator'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Create an account for your collaborator so they can join your workspace.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Collaborator name',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person_outline),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a name';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            Text('Pick a colour', style: theme.textTheme.bodyMedium),
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
                      width: 32,
                      height: 32,
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
                              color: Colors.white, size: 16)
                          : null,
                    ),
                  ),
                );
              }),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _isLoading ? null : _invite,
          child: _isLoading
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Invite'),
        ),
      ],
    );
  }
}
