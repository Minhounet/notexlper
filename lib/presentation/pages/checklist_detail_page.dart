import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/category.dart';
import '../../domain/entities/checklist_item.dart';
import '../../domain/entities/checklist_note.dart';
import '../models/display_mode.dart';
import '../providers/category_providers.dart';
import '../providers/checklist_providers.dart';
import 'category_admin_page.dart';

class ChecklistDetailPage extends ConsumerStatefulWidget {
  final ChecklistNote note;

  const ChecklistDetailPage({super.key, required this.note});

  @override
  ConsumerState<ChecklistDetailPage> createState() => _ChecklistDetailPageState();
}

class _ChecklistDetailPageState extends ConsumerState<ChecklistDetailPage> {
  late ChecklistNote _note;
  late TextEditingController _titleController;
  final Map<String, TextEditingController> _itemControllers = {};
  ChecklistDisplayMode _displayMode = ChecklistDisplayMode.flat;
  bool _checkedAtBottom = false;

  @override
  void initState() {
    super.initState();
    _note = widget.note;
    _titleController = TextEditingController(text: _note.title);
  }

  @override
  void dispose() {
    _titleController.dispose();
    for (final controller in _itemControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  TextEditingController _getItemController(ChecklistItem item) {
    if (!_itemControllers.containsKey(item.id)) {
      _itemControllers[item.id] = TextEditingController(text: item.text);
    }
    return _itemControllers[item.id]!;
  }

  Future<void> _save() async {
    final repository = ref.read(checklistRepositoryProvider);
    await repository.updateNote(_note);
  }

  void _updateTitle(String title) {
    setState(() {
      _note = _note.copyWith(title: title, updatedAt: DateTime.now());
    });
    _save();
  }

  void _toggleItem(String itemId) {
    setState(() {
      final updatedItems = _note.items.map((item) {
        if (item.id == itemId) {
          return item.copyWith(isChecked: !item.isChecked);
        }
        return item;
      }).toList();
      _note = _note.copyWith(items: updatedItems, updatedAt: DateTime.now());
    });
    _save();
  }

  void _updateItemText(String itemId, String text) {
    setState(() {
      final updatedItems = _note.items.map((item) {
        if (item.id == itemId) {
          return item.copyWith(text: text);
        }
        return item;
      }).toList();
      _note = _note.copyWith(items: updatedItems, updatedAt: DateTime.now());
    });
    _save();
  }

  void _addItem() {
    final newItem = ChecklistItem(
      id: 'item-${DateTime.now().millisecondsSinceEpoch}',
      text: '',
      order: _note.items.length,
    );
    setState(() {
      _note = _note.copyWith(
        items: [..._note.items, newItem],
        updatedAt: DateTime.now(),
      );
    });
    _save();
  }

  void _removeItem(String itemId) {
    _itemControllers.remove(itemId)?.dispose();
    setState(() {
      final updatedItems = _note.items.where((item) => item.id != itemId).toList();
      _note = _note.copyWith(items: updatedItems, updatedAt: DateTime.now());
    });
    _save();
  }

  void _updateItemCategory(String itemId, String? categoryId) {
    setState(() {
      final updatedItems = _note.items.map((item) {
        if (item.id == itemId) {
          return item.copyWith(
            categoryId: categoryId,
            clearCategoryId: categoryId == null,
          );
        }
        return item;
      }).toList();
      _note = _note.copyWith(items: updatedItems, updatedAt: DateTime.now());
    });
    _save();
  }

  List<ChecklistItem> _applySorting(List<ChecklistItem> items) {
    if (!_checkedAtBottom) return items;
    final unchecked = items.where((i) => !i.isChecked).toList();
    final checked = items.where((i) => i.isChecked).toList();
    return [...unchecked, ...checked];
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sortedItems = _note.sortedItems;
    final categoriesAsync = ref.watch(categoryListProvider);

    return PopScope(
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) {
          ref.read(checklistListProvider.notifier).loadNotes();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            _note.title.isEmpty ? 'New Checklist' : _note.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          actions: [
            Center(
              child: Text(
                '${_note.completedCount}/${_note.totalCount}',
                style: theme.textTheme.bodyMedium,
              ),
            ),
            _DisplayModeMenuButton(
              displayMode: _displayMode,
              checkedAtBottom: _checkedAtBottom,
              onDisplayModeChanged: (mode) {
                setState(() => _displayMode = mode);
              },
              onCheckedAtBottomChanged: (value) {
                setState(() => _checkedAtBottom = value);
              },
            ),
          ],
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: TextField(
                controller: _titleController,
                decoration: const InputDecoration(
                  hintText: 'Checklist title',
                  border: InputBorder.none,
                ),
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                onChanged: _updateTitle,
              ),
            ),
            const Divider(),
            Expanded(
              child: categoriesAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (_, __) => _buildContent(sortedItems, []),
                data: (categories) => _buildContent(sortedItems, categories),
              ),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: _addItem,
          child: const Icon(Icons.add),
        ),
      ),
    );
  }

  Widget _buildContent(List<ChecklistItem> sortedItems, List<Category> categories) {
    switch (_displayMode) {
      case ChecklistDisplayMode.flat:
        return _buildFlatList(_applySorting(sortedItems), categories);
      case ChecklistDisplayMode.groupedByCategory:
        return _buildGroupedList(sortedItems, categories);
    }
  }

  Widget _buildFlatList(List<ChecklistItem> items, List<Category> categories) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return _ChecklistItemTile(
          key: ValueKey(item.id),
          item: item,
          controller: _getItemController(item),
          categories: categories,
          onToggle: () => _toggleItem(item.id),
          onTextChanged: (text) => _updateItemText(item.id, text),
          onDelete: () => _removeItem(item.id),
          onCategoryChanged: (categoryId) =>
              _updateItemCategory(item.id, categoryId),
          onCreateCategory: () => _createCategoryInline(item.id),
        );
      },
    );
  }

  Widget _buildGroupedList(List<ChecklistItem> sortedItems, List<Category> categories) {
    final categoryMap = {for (final c in categories) c.id: c};

    // Group items by categoryId
    final Map<String?, List<ChecklistItem>> groups = {};
    for (final item in sortedItems) {
      groups.putIfAbsent(item.categoryId, () => []).add(item);
    }

    // Build ordered list of category keys: known categories first (in categories order),
    // then null (uncategorized) last
    final orderedKeys = <String?>[];
    for (final cat in categories) {
      if (groups.containsKey(cat.id)) {
        orderedKeys.add(cat.id);
      }
    }
    // Add any unknown categoryIds (category was deleted but items still reference it)
    for (final key in groups.keys) {
      if (key != null && !orderedKeys.contains(key)) {
        orderedKeys.add(key);
      }
    }
    if (groups.containsKey(null)) {
      orderedKeys.add(null);
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      itemCount: orderedKeys.length,
      itemBuilder: (context, index) {
        final categoryId = orderedKeys[index];
        final category = categoryId != null ? categoryMap[categoryId] : null;
        final groupItems = _applySorting(groups[categoryId]!);

        return _CategoryGroup(
          category: category,
          categoryId: categoryId,
          items: groupItems,
          allCategories: categories,
          getItemController: _getItemController,
          onToggle: _toggleItem,
          onTextChanged: _updateItemText,
          onDelete: _removeItem,
          onCategoryChanged: _updateItemCategory,
          onCreateCategoryInline: _createCategoryInline,
        );
      },
    );
  }

  Future<void> _createCategoryInline(String itemId) async {
    final result = await showDialog<Category>(
      context: context,
      builder: (context) => const _InlineCategoryFormDialog(),
    );
    if (result != null) {
      await ref.read(categoryListProvider.notifier).createCategory(result);
      _updateItemCategory(itemId, result.id);
    }
  }
}

class _DisplayModeMenuButton extends StatelessWidget {
  final ChecklistDisplayMode displayMode;
  final bool checkedAtBottom;
  final ValueChanged<ChecklistDisplayMode> onDisplayModeChanged;
  final ValueChanged<bool> onCheckedAtBottomChanged;

  const _DisplayModeMenuButton({
    required this.displayMode,
    required this.checkedAtBottom,
    required this.onDisplayModeChanged,
    required this.onCheckedAtBottomChanged,
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.view_list),
      tooltip: 'Display mode',
      onSelected: (value) {
        switch (value) {
          case 'flat':
            onDisplayModeChanged(ChecklistDisplayMode.flat);
          case 'grouped':
            onDisplayModeChanged(ChecklistDisplayMode.groupedByCategory);
          case 'checked_bottom':
            onCheckedAtBottomChanged(!checkedAtBottom);
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem(
          value: 'flat',
          child: Row(
            children: [
              Icon(
                Icons.list,
                color: displayMode == ChecklistDisplayMode.flat
                    ? Theme.of(context).colorScheme.primary
                    : null,
              ),
              const SizedBox(width: 12),
              const Text('Flat view'),
              if (displayMode == ChecklistDisplayMode.flat) ...[
                const Spacer(),
                Icon(Icons.check, color: Theme.of(context).colorScheme.primary, size: 18),
              ],
            ],
          ),
        ),
        PopupMenuItem(
          value: 'grouped',
          child: Row(
            children: [
              Icon(
                Icons.category,
                color: displayMode == ChecklistDisplayMode.groupedByCategory
                    ? Theme.of(context).colorScheme.primary
                    : null,
              ),
              const SizedBox(width: 12),
              const Text('Group by category'),
              if (displayMode == ChecklistDisplayMode.groupedByCategory) ...[
                const Spacer(),
                Icon(Icons.check, color: Theme.of(context).colorScheme.primary, size: 18),
              ],
            ],
          ),
        ),
        const PopupMenuDivider(),
        PopupMenuItem(
          value: 'checked_bottom',
          child: Row(
            children: [
              Icon(
                Icons.vertical_align_bottom,
                color: checkedAtBottom
                    ? Theme.of(context).colorScheme.primary
                    : null,
              ),
              const SizedBox(width: 12),
              const Text('Checked at bottom'),
              if (checkedAtBottom) ...[
                const Spacer(),
                Icon(Icons.check, color: Theme.of(context).colorScheme.primary, size: 18),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _CategoryGroup extends StatelessWidget {
  final Category? category;
  final String? categoryId;
  final List<ChecklistItem> items;
  final List<Category> allCategories;
  final TextEditingController Function(ChecklistItem) getItemController;
  final void Function(String) onToggle;
  final void Function(String, String) onTextChanged;
  final void Function(String) onDelete;
  final void Function(String, String?) onCategoryChanged;
  final void Function(String) onCreateCategoryInline;

  const _CategoryGroup({
    required this.category,
    required this.categoryId,
    required this.items,
    required this.allCategories,
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
        ...items.map((item) => _ChecklistItemTile(
              key: ValueKey(item.id),
              item: item,
              controller: getItemController(item),
              categories: allCategories,
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

class _ChecklistItemTile extends StatelessWidget {
  final ChecklistItem item;
  final TextEditingController controller;
  final List<Category> categories;
  final VoidCallback onToggle;
  final ValueChanged<String> onTextChanged;
  final VoidCallback onDelete;
  final ValueChanged<String?> onCategoryChanged;
  final VoidCallback onCreateCategory;

  const _ChecklistItemTile({
    super.key,
    required this.item,
    required this.controller,
    required this.categories,
    required this.onToggle,
    required this.onTextChanged,
    required this.onDelete,
    required this.onCategoryChanged,
    required this.onCreateCategory,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final category = item.categoryId != null
        ? categories.where((c) => c.id == item.categoryId).firstOrNull
        : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Checkbox(
              value: item.isChecked,
              onChanged: (_) => onToggle(),
            ),
            Expanded(
              child: TextField(
                controller: controller,
                decoration: const InputDecoration(
                  hintText: 'List item',
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(vertical: 8),
                ),
                style: theme.textTheme.bodyLarge?.copyWith(
                  decoration: item.isChecked ? TextDecoration.lineThrough : null,
                  color: item.isChecked
                      ? theme.colorScheme.onSurfaceVariant
                      : null,
                ),
                onChanged: onTextChanged,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close, size: 18),
              onPressed: onDelete,
              tooltip: 'Remove item',
            ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.only(left: 48, bottom: 4),
          child: _CategorySelector(
            categories: categories,
            selectedCategory: category,
            onCategoryChanged: onCategoryChanged,
            onCreateCategory: onCreateCategory,
          ),
        ),
      ],
    );
  }
}

class _CategorySelector extends StatelessWidget {
  final List<Category> categories;
  final Category? selectedCategory;
  final ValueChanged<String?> onCategoryChanged;
  final VoidCallback onCreateCategory;

  const _CategorySelector({
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
      builder: (context) => _CategoryPickerSheet(
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

class _CategoryPickerSheet extends StatelessWidget {
  final List<Category> categories;
  final String? selectedCategoryId;
  final ValueChanged<String> onCategorySelected;
  final VoidCallback onCreateCategory;
  final VoidCallback onClearCategory;

  const _CategoryPickerSheet({
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

/// Inline dialog for creating a category from within the checklist detail page.
class _InlineCategoryFormDialog extends StatefulWidget {
  const _InlineCategoryFormDialog();

  @override
  State<_InlineCategoryFormDialog> createState() =>
      _InlineCategoryFormDialogState();
}

class _InlineCategoryFormDialogState extends State<_InlineCategoryFormDialog> {
  late TextEditingController _nameController;
  late Color _selectedColor;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _selectedColor = categoryColors.first;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('New Category'),
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
              id: 'cat-${DateTime.now().millisecondsSinceEpoch}',
              name: name,
              colorValue: _selectedColor.value,
            );
            Navigator.pop(context, category);
          },
          child: const Text('Create'),
        ),
      ],
    );
  }
}
