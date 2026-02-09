import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/category.dart';
import '../../domain/entities/checklist_note.dart';
import '../pages/checklist_detail_page.dart';
import '../providers/checklist_providers.dart';

/// A card shown on the home page that previews a checklist note.
///
/// Displays the title, up to 5 item previews (with checkbox icons
/// and optional category badges), a progress counter, and a delete
/// button.
class ChecklistCard extends ConsumerWidget {
  final ChecklistNote note;
  final List<Category> categories;

  const ChecklistCard({
    super.key,
    required this.note,
    required this.categories,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final previewItems = note.sortedItems.take(5).toList();
    final hasMore = note.items.length > 5;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => ChecklistDetailPage(note: note),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (note.title.isNotEmpty)
                Text(
                  note.title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              if (note.title.isNotEmpty) const SizedBox(height: 8),
              ...previewItems.map((item) {
                final category = item.categoryId != null
                    ? categories
                        .where((c) => c.id == item.categoryId)
                        .firstOrNull
                    : null;
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    children: [
                      Icon(
                        item.isChecked
                            ? Icons.check_box
                            : Icons.check_box_outline_blank,
                        size: 20,
                        color: item.isChecked
                            ? theme.colorScheme.primary
                            : theme.colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          item.text.isEmpty ? 'Empty item' : item.text,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            decoration: item.isChecked
                                ? TextDecoration.lineThrough
                                : null,
                            color: item.isChecked
                                ? theme.colorScheme.onSurfaceVariant
                                : null,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (category != null)
                        Container(
                          margin: const EdgeInsets.only(left: 4),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color:
                                Color(category.colorValue).withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            category.name,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: Color(category.colorValue),
                              fontSize: 10,
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              }),
              if (hasMore)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    '+${note.items.length - 5} more',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${note.completedCount}/${note.totalCount} done',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, size: 20),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () => _confirmDelete(context, ref),
                    tooltip: 'Delete checklist',
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete checklist?'),
        content: const Text('This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      ref.read(checklistListProvider.notifier).deleteNote(note.id);
    }
  }
}
