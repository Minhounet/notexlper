import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_constants.dart';
import '../../domain/entities/checklist_item.dart';
import '../../domain/entities/checklist_note.dart';
import '../providers/actor_providers.dart';
import '../providers/category_providers.dart';
import '../providers/checklist_providers.dart';
import '../widgets/checklist_card.dart';
import 'category_admin_page.dart';
import 'checklist_detail_page.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notesAsync = ref.watch(checklistListProvider);
    final categoriesAsync = ref.watch(categoryListProvider);
    final currentActor = ref.watch(currentActorProvider);
    final actorsAsync = ref.watch(actorListProvider);

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
        title: Text(
          AppConstants.appName,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        centerTitle: true,
        actions: [
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
                onPressed: () => ref.read(checklistListProvider.notifier).loadNotes(),
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
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No checklists yet',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tap + to create your first checklist',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
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

  Future<void> _showSwitchActorDialog(BuildContext context, WidgetRef ref) async {
    final actorsAsync = ref.read(actorListProvider);
    final actors = actorsAsync.valueOrNull ?? [];
    final currentActor = ref.read(currentActorProvider);

    final selected = await showDialog(
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
                  Icon(Icons.check, color: Theme.of(context).colorScheme.primary),
              ],
            ),
          );
        }).toList(),
      ),
    );

    if (selected != null) {
      ref.read(currentActorProvider.notifier).login(selected);
    }
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
