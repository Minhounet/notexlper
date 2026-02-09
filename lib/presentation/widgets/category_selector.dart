import 'package:flutter/material.dart';

import '../../domain/entities/category.dart';
import 'category_picker_sheet.dart';

/// A compact widget that shows the current category as a chip, or
/// an "Add category" label when no category is selected.
///
/// Tapping it opens a [CategoryPickerSheet] bottom sheet where the
/// user can choose an existing category, clear the selection, or
/// create a new one.
class CategorySelector extends StatelessWidget {
  final List<Category> categories;
  final Category? selectedCategory;
  final ValueChanged<String?> onCategoryChanged;
  final VoidCallback onCreateCategory;

  const CategorySelector({
    super.key,
    required this.categories,
    required this.selectedCategory,
    required this.onCategoryChanged,
    required this.onCreateCategory,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (selectedCategory != null) {
      return GestureDetector(
        onTap: () => _showCategoryPicker(context),
        child: Chip(
          avatar: CircleAvatar(
            backgroundColor: Color(selectedCategory!.colorValue),
            radius: 8,
          ),
          label: Text(
            selectedCategory!.name,
            style: theme.textTheme.labelSmall,
          ),
          deleteIcon: const Icon(Icons.close, size: 14),
          onDeleted: () => onCategoryChanged(null),
          visualDensity: VisualDensity.compact,
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
      );
    }

    return InkWell(
      onTap: () => _showCategoryPicker(context),
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.label_outline,
              size: 14,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 4),
            Text(
              'Add category',
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCategoryPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => CategoryPickerSheet(
        categories: categories,
        selectedCategoryId: selectedCategory?.id,
        onCategorySelected: (id) {
          onCategoryChanged(id);
          Navigator.pop(context);
        },
        onCreateCategory: () {
          Navigator.pop(context);
          onCreateCategory();
        },
        onClearCategory: () {
          onCategoryChanged(null);
          Navigator.pop(context);
        },
      ),
    );
  }
}
