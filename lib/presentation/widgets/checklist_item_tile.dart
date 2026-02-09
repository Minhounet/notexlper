import 'package:flutter/material.dart';

import '../../domain/entities/category.dart';
import '../../domain/entities/checklist_item.dart';
import 'category_selector.dart';

/// A single checklist item row: checkbox + text field + delete button.
///
/// Plays a brief highlight animation when [justToggled] becomes true
/// (green flash for checked, blue flash for unchecked).
///
/// The optional [showCategory] flag controls whether the category
/// selector chip appears below the item text.
class ChecklistItemTile extends StatefulWidget {
  final ChecklistItem item;
  final TextEditingController controller;
  final List<Category> categories;
  final bool showCategory;
  final bool justToggled;
  final VoidCallback onToggle;
  final ValueChanged<String> onTextChanged;
  final VoidCallback onDelete;
  final ValueChanged<String?> onCategoryChanged;
  final VoidCallback onCreateCategory;

  const ChecklistItemTile({
    super.key,
    required this.item,
    required this.controller,
    required this.categories,
    this.showCategory = true,
    this.justToggled = false,
    required this.onToggle,
    required this.onTextChanged,
    required this.onDelete,
    required this.onCategoryChanged,
    required this.onCreateCategory,
  });

  @override
  State<ChecklistItemTile> createState() => _ChecklistItemTileState();
}

class _ChecklistItemTileState extends State<ChecklistItemTile>
    with SingleTickerProviderStateMixin {
  late AnimationController _highlightController;
  late Animation<double> _highlightAnimation;

  @override
  void initState() {
    super.initState();
    _highlightController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _highlightAnimation = CurvedAnimation(
      parent: _highlightController,
      curve: Curves.easeOut,
    );
    if (widget.justToggled) {
      _highlightController.forward(from: 0);
    }
  }

  @override
  void didUpdateWidget(ChecklistItemTile old) {
    super.didUpdateWidget(old);
    if (widget.justToggled && !old.justToggled) {
      _highlightController.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _highlightController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final category = widget.item.categoryId != null
        ? widget.categories
            .where((c) => c.id == widget.item.categoryId)
            .firstOrNull
        : null;

    final highlightColor = widget.item.isChecked
        ? Colors.green.withOpacity(0.25)
        : Colors.blue.withOpacity(0.15);

    return AnimatedBuilder(
      animation: _highlightAnimation,
      builder: (context, child) {
        final opacity = (1.0 - _highlightAnimation.value);
        return Container(
          decoration: BoxDecoration(
            color: widget.justToggled
                ? highlightColor.withOpacity(highlightColor.opacity * opacity)
                : null,
            borderRadius: BorderRadius.circular(8),
          ),
          child: child,
        );
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Checkbox(
                value: widget.item.isChecked,
                onChanged: (_) => widget.onToggle(),
              ),
              Expanded(
                child: TextField(
                  controller: widget.controller,
                  decoration: const InputDecoration(
                    hintText: 'List item',
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(vertical: 8),
                  ),
                  style: theme.textTheme.bodyLarge?.copyWith(
                    decoration:
                        widget.item.isChecked ? TextDecoration.lineThrough : null,
                    color: widget.item.isChecked
                        ? theme.colorScheme.onSurfaceVariant
                        : null,
                  ),
                  onChanged: widget.onTextChanged,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, size: 18),
                onPressed: widget.onDelete,
                tooltip: 'Remove item',
              ),
            ],
          ),
          if (widget.showCategory)
            Padding(
              padding: const EdgeInsets.only(left: 48, bottom: 4),
              child: CategorySelector(
                categories: widget.categories,
                selectedCategory: category,
                onCategoryChanged: widget.onCategoryChanged,
                onCreateCategory: widget.onCreateCategory,
              ),
            ),
        ],
      ),
    );
  }
}
