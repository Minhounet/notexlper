import 'package:flutter/material.dart';

import '../../domain/entities/actor.dart';

/// Bottom sheet for selecting actors to assign to a checklist.
class ActorPickerSheet extends StatelessWidget {
  final List<Actor> actors;
  final List<String> assignedIds;
  final String? creatorId;
  final ValueChanged<Actor> onToggleActor;

  const ActorPickerSheet({
    super.key,
    required this.actors,
    required this.assignedIds,
    this.creatorId,
    required this.onToggleActor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Assign people',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 8),
          ...actors.map((actor) {
            final isAssigned = assignedIds.contains(actor.id);
            final isCreator = actor.id == creatorId;
            return ListTile(
              leading: CircleAvatar(
                backgroundColor: Color(actor.colorValue),
                child: Text(
                  actor.name[0].toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              title: Text(actor.name),
              subtitle: isCreator ? const Text('Creator') : null,
              trailing: isAssigned
                  ? Icon(Icons.check_circle, color: theme.colorScheme.primary)
                  : const Icon(Icons.circle_outlined),
              onTap: isCreator ? null : () => onToggleActor(actor),
            );
          }),
        ],
      ),
    );
  }
}
