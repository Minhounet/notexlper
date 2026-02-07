import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/checklist_item.dart';
import '../../domain/entities/checklist_note.dart';
import '../providers/checklist_providers.dart';

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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sortedItems = _note.sortedItems;

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
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                itemCount: sortedItems.length,
                itemBuilder: (context, index) {
                  final item = sortedItems[index];
                  return _ChecklistItemTile(
                    key: ValueKey(item.id),
                    item: item,
                    controller: _getItemController(item),
                    onToggle: () => _toggleItem(item.id),
                    onTextChanged: (text) => _updateItemText(item.id, text),
                    onDelete: () => _removeItem(item.id),
                  );
                },
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
}

class _ChecklistItemTile extends StatelessWidget {
  final ChecklistItem item;
  final TextEditingController controller;
  final VoidCallback onToggle;
  final ValueChanged<String> onTextChanged;
  final VoidCallback onDelete;

  const _ChecklistItemTile({
    super.key,
    required this.item,
    required this.controller,
    required this.onToggle,
    required this.onTextChanged,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
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
    );
  }
}
