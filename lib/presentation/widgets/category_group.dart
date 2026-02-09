import 'package:flutter/material.dart';

import '../../domain/entities/category.dart';
import '../../domain/entities/checklist_item.dart';
import 'checklist_item_tile.dart';

/// Renders a group header (colored dot + category name + item count)
/// followed by all the items that belong to that category.
///
/// Used in the "Group by category" display mode of the checklist
/// detail page.
class CategoryGroup extends StatelessWidget {
  final Category? category;
  final String? categoryId;
  final List<ChecklistItem> items;
  final List<Category> allCategories;
  final String? justToggledItemId;
  final TextEditingController Function(ChecklistItem) getItemController;
  final void Function(String) onToggle;
  final void Function(String, String) onTextChanged;
  final void Function(String) onDelete;
  final void Function(String, String?) onCategoryChanged;
  final void Function(String) onCreateCategoryInline;

  const CategoryGroup({
    super.key,
    required this.category,
    required this.categoryId,
    required this.items,
    required this.allCategories,
    required this.justToggledItemId,
    required this.getItemController,
    required this.onToggle,
    required this.onTextChanged,
    required this.onDelete,
    required this.onCategoryChanged,
    required this.onCreateCategoryInline,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final headerText = category?.name ?? 'Uncategorized';
    final headerColor = category != null
        ? Color(category!.colorValue)
        : theme.colorScheme.onSurfaceVariant;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 12, 8, 4),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: headerColor,
                radius: 6,
              ),
              const SizedBox(width: 8),
              Text(
                headerText,
                style: theme.textTheme.titleSmall?.copyWith(
                  color: headerColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '(${items.length})',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        ...items.map((item) => ChecklistItemTile(
              key: ValueKey(item.id),
              item: item,
              controller: getItemController(item),
              categories: allCategories,
              showCategory: false,
              justToggled: justToggledItemId == item.id,
              onToggle: () => onToggle(item.id),
              onTextChanged: (text) => onTextChanged(item.id, text),
              onDelete: () => onDelete(item.id),
              onCategoryChanged: (catId) => onCategoryChanged(item.id, catId),
              onCreateCategory: () => onCreateCategoryInline(item.id),
            )),
      ],
    );
  }
}
