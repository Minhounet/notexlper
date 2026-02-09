import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/category.dart';
import '../providers/category_providers.dart';
import 'category_form_dialog.dart';

/// A card that represents one category in the category admin list.
///
/// Shows the category color, name, and edit / delete action buttons.
class CategoryTile extends ConsumerWidget {
  final Category category;

  const CategoryTile({super.key, required this.category});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final color = Color(category.colorValue);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color,
          child: const Icon(Icons.label, color: Colors.white),
        ),
        title: Text(
          category.name,
          style: theme.textTheme.titleMedium,
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              onPressed: () => _editCategory(context, ref),
              tooltip: 'Edit category',
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: () => _confirmDelete(context, ref),
              tooltip: 'Delete category',
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _editCategory(BuildContext context, WidgetRef ref) async {
    final result = await showDialog<Category>(
      context: context,
      builder: (context) => CategoryFormDialog(category: category),
    );
    if (result != null) {
      await ref.read(categoryListProvider.notifier).updateCategory(result);
    }
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete category?'),
        content: Text(
            'Are you sure you want to delete "${category.name}"? Items using this category will be unassigned.'),
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
      await ref
          .read(categoryListProvider.notifier)
          .deleteCategory(category.id);
    }
  }
}
