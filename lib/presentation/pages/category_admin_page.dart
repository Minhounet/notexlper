import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/category.dart';
import '../providers/category_providers.dart';

/// Available colors for category selection.
const List<Color> categoryColors = [
  Colors.red,
  Colors.pink,
  Colors.purple,
  Colors.deepPurple,
  Colors.indigo,
  Colors.blue,
  Colors.teal,
  Colors.green,
  Colors.lime,
  Colors.orange,
  Colors.brown,
  Colors.grey,
];

class CategoryAdminPage extends ConsumerWidget {
  const CategoryAdminPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(categoryListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Categories'),
      ),
      body: categoriesAsync.when(
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
                    ref.read(categoryListProvider.notifier).loadCategories(),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (categories) {
          if (categories.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.label_outline,
                    size: 80,
                    color:
                        Theme.of(context).colorScheme.primary.withOpacity(0.5),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No categories yet',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tap + to create your first category',
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
            itemCount: categories.length,
            itemBuilder: (context, index) {
              final category = categories[index];
              return _CategoryTile(category: category);
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCategoryDialog(context, ref),
        child: const Icon(Icons.add),
      ),
    );
  }

  Future<void> _showCategoryDialog(BuildContext context, WidgetRef ref) async {
    final result = await showDialog<Category>(
      context: context,
      builder: (context) => const _CategoryFormDialog(),
    );
    if (result != null) {
      await ref.read(categoryListProvider.notifier).createCategory(result);
    }
  }
}

class _CategoryTile extends ConsumerWidget {
  final Category category;

  const _CategoryTile({required this.category});

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
      builder: (context) => _CategoryFormDialog(category: category),
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
      await ref.read(categoryListProvider.notifier).deleteCategory(category.id);
    }
  }
}

class _CategoryFormDialog extends StatefulWidget {
  final Category? category;

  const _CategoryFormDialog({this.category});

  @override
  State<_CategoryFormDialog> createState() => _CategoryFormDialogState();
}

class _CategoryFormDialogState extends State<_CategoryFormDialog> {
  late TextEditingController _nameController;
  late Color _selectedColor;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.category?.name ?? '');
    _selectedColor = widget.category != null
        ? Color(widget.category!.colorValue)
        : categoryColors.first;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.category != null;

    return AlertDialog(
      title: Text(isEditing ? 'Edit Category' : 'New Category'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _nameController,
            autofocus: true,
            decoration: const InputDecoration(
              labelText: 'Category name',
              hintText: 'Enter category name',
            ),
          ),
          const SizedBox(height: 16),
          const Align(
            alignment: Alignment.centerLeft,
            child: Text('Color'),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: categoryColors.map((color) {
              final isSelected = _selectedColor.value == color.value;
              return GestureDetector(
                onTap: () => setState(() => _selectedColor = color),
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    border: isSelected
                        ? Border.all(
                            color: Theme.of(context).colorScheme.onSurface,
                            width: 3,
                          )
                        : null,
                  ),
                  child: isSelected
                      ? const Icon(Icons.check, color: Colors.white, size: 20)
                      : null,
                ),
              );
            }).toList(),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            final name = _nameController.text.trim();
            if (name.isEmpty) return;

            final category = Category(
              id: widget.category?.id ??
                  'cat-${DateTime.now().millisecondsSinceEpoch}',
              name: name,
              colorValue: _selectedColor.value,
            );
            Navigator.pop(context, category);
          },
          child: Text(isEditing ? 'Save' : 'Create'),
        ),
      ],
    );
  }
}
