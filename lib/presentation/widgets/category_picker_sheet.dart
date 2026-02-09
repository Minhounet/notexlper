import 'package:flutter/material.dart';

import '../../domain/entities/category.dart';

/// A bottom-sheet that lists available categories for selection.
///
/// Shows each category with its color, a check mark on the currently
/// selected one, an option to clear the selection, and a
/// "Create new category" action at the bottom.
class CategoryPickerSheet extends StatelessWidget {
  final List<Category> categories;
  final String? selectedCategoryId;
  final ValueChanged<String> onCategorySelected;
  final VoidCallback onCreateCategory;
  final VoidCallback onClearCategory;

  const CategoryPickerSheet({
    super.key,
    required this.categories,
    required this.selectedCategoryId,
    required this.onCategorySelected,
    required this.onCreateCategory,
    required this.onClearCategory,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Select Category',
              style: theme.textTheme.titleMedium,
            ),
          ),
          if (selectedCategoryId != null)
            ListTile(
              leading: const Icon(Icons.clear),
              title: const Text('No category'),
              onTap: onClearCategory,
            ),
          ...categories.map((cat) => ListTile(
                leading: CircleAvatar(
                  backgroundColor: Color(cat.colorValue),
                  radius: 14,
                  child: cat.id == selectedCategoryId
                      ? const Icon(Icons.check, color: Colors.white, size: 16)
                      : null,
                ),
                title: Text(cat.name),
                selected: cat.id == selectedCategoryId,
                onTap: () => onCategorySelected(cat.id),
              )),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.add),
            title: const Text('Create new category'),
            onTap: onCreateCategory,
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
