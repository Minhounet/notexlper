import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/category.dart';
import '../../domain/entities/checklist_item.dart';
import '../../domain/entities/checklist_note.dart';
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
            const SizedBox(width: 16),
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
                error: (_, __) => _buildItemList(sortedItems, []),
                data: (categories) => _buildItemList(sortedItems, categories),
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

  Widget _buildItemList(List<ChecklistItem> sortedItems, List<Category> categories) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      itemCount: sortedItems.length,
      itemBuilder: (context, index) {
        final item = sortedItems[index];
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
