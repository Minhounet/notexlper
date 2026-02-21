import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../domain/entities/actor.dart';
import '../../domain/entities/category.dart';
import '../../domain/entities/checklist_item.dart';
import '../../domain/entities/checklist_note.dart';
import '../../domain/entities/reminder.dart';
import '../../domain/services/notification_service.dart';
import '../models/display_mode.dart';
import '../providers/actor_providers.dart';
import '../providers/category_providers.dart';
import '../providers/checklist_providers.dart';
import '../providers/notification_providers.dart';
import '../widgets/actor_avatar_row.dart';
import '../widgets/actor_picker_sheet.dart';
import '../widgets/category_form_dialog.dart';
import '../widgets/category_group.dart';
import '../widgets/checked_separator.dart';
import '../widgets/checklist_item_tile.dart';
import '../widgets/display_mode_menu_button.dart';
import '../widgets/reminder_picker_sheet.dart';

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

  // Animation tracking
  String? _justToggledItemId;
  String? _pendingMoveItemId;
  Timer? _moveTimer;
  Timer? _emphasisTimer;

  @override
  void initState() {
    super.initState();
    _note = widget.note;
    _titleController = TextEditingController(text: _note.title);
  }

  @override
  void dispose() {
    _moveTimer?.cancel();
    _emphasisTimer?.cancel();
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
    final item = _note.items.firstWhere((i) => i.id == itemId);
    final isBeingChecked = !item.isChecked;

    _moveTimer?.cancel();
    _emphasisTimer?.cancel();

    setState(() {
      _justToggledItemId = itemId;
      if (_checkedAtBottom && isBeingChecked) {
        _pendingMoveItemId = itemId;
      }
      final updatedItems = _note.items.map((i) {
        if (i.id == itemId) {
          return i.copyWith(isChecked: !i.isChecked);
        }
        return i;
      }).toList();
      _note = _note.copyWith(items: updatedItems, updatedAt: DateTime.now());
    });
    _save();

    if (_checkedAtBottom && isBeingChecked) {
      _moveTimer = Timer(const Duration(milliseconds: 500), () {
        if (mounted) {
          setState(() {
            _pendingMoveItemId = null;
            _justToggledItemId = null;
          });
        }
      });
    } else {
      _emphasisTimer = Timer(const Duration(milliseconds: 600), () {
        if (mounted) {
          setState(() {
            _justToggledItemId = null;
          });
        }
      });
    }
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

  void _toggleAssignee(Actor actor) {
    setState(() {
      final currentIds = List<String>.from(_note.assigneeIds);
      if (currentIds.contains(actor.id)) {
        currentIds.remove(actor.id);
      } else {
        currentIds.add(actor.id);
      }
      _note = _note.copyWith(assigneeIds: currentIds, updatedAt: DateTime.now());
    });
    _save();
  }

  void _showAssigneePicker(List<Actor> allActors) {
    showModalBottomSheet(
      context: context,
      builder: (_) => ActorPickerSheet(
        actors: allActors,
        assignedIds: _note.assigneeIds,
        creatorId: _note.creatorId,
        onToggleActor: (actor) {
          _toggleAssignee(actor);
          Navigator.pop(context);
          // Reopen immediately to reflect updated state
          Future.microtask(() {
            if (mounted) _showAssigneePicker(allActors);
          });
        },
      ),
    );
  }

  void _showReminderPicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => ReminderPickerSheet(
        existingReminder: _note.reminder,
        onSave: _setReminder,
        onRemove: _note.reminder != null ? _removeReminder : null,
      ),
    );
  }

  void _setReminder(Reminder reminder) {
    setState(() {
      _note = _note.copyWith(reminder: reminder, updatedAt: DateTime.now());
    });
    _save();
    _scheduleNotification(reminder);
  }

  void _removeReminder() {
    final notifService = ref.read(notificationServiceProvider);
    notifService.cancelReminder(_note.id);
    setState(() {
      _note = _note.copyWith(clearReminder: true, updatedAt: DateTime.now());
    });
    _save();
  }

  void _scheduleNotification(Reminder reminder) {
    final notifService = ref.read(notificationServiceProvider);
    final title = _note.title.isEmpty ? 'Checklist Reminder' : _note.title;
    final unchecked = _note.items.where((i) => !i.isChecked).length;
    final body = '$unchecked item(s) remaining'
        '${reminder.frequency != ReminderFrequency.once ? ' (${reminder.frequency.label})' : ''}';

    // Show confirmation FIRST (this is proven to work)
    final summary = _formatReminderSummary(reminder);
    notifService.showNow(
      title: 'Reminder set: $title',
      body: summary,
    );

    // Then schedule the future notification (fire-and-forget, errors logged)
    notifService.scheduleReminder(ScheduledNotification(
      noteId: _note.id,
      title: title,
      body: body,
      recipientIds: _note.assigneeIds,
      reminder: reminder,
    ));
  }

  List<ChecklistItem> _applySorting(List<ChecklistItem> items) {
    if (!_checkedAtBottom) return items;
    final unchecked = items
        .where((i) => !i.isChecked || i.id == _pendingMoveItemId)
        .toList();
    final checked = items
        .where((i) => i.isChecked && i.id != _pendingMoveItemId)
        .toList();
    return [...unchecked, ...checked];
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sortedItems = _note.sortedItems;
    final categoriesAsync = ref.watch(categoryListProvider);
    final actorsAsync = ref.watch(actorListProvider);
    final allActors = actorsAsync.valueOrNull ?? [];
    final assignedActors = allActors
        .where((a) => _note.assigneeIds.contains(a.id))
        .toList();

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
            IconButton(
              icon: Icon(
                _note.hasActiveReminder
                    ? Icons.notifications_active
                    : Icons.notifications_none,
                color: _note.hasActiveReminder
                    ? theme.colorScheme.primary
                    : null,
              ),
              tooltip: _note.hasActiveReminder ? 'Edit reminder' : 'Set reminder',
              onPressed: _showReminderPicker,
            ),
            IconButton(
              icon: const Icon(Icons.person_add_outlined),
              tooltip: 'Manage assignees',
              onPressed: () => _showAssigneePicker(allActors),
            ),
            DisplayModeMenuButton(
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
            if (assignedActors.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                child: GestureDetector(
                  onTap: () => _showAssigneePicker(allActors),
                  child: Row(
                    children: [
                      ActorAvatarRow(actors: assignedActors),
                      const SizedBox(width: 8),
                      Text(
                        assignedActors.map((a) => a.name).join(', '),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            if (_note.hasActiveReminder)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
                child: GestureDetector(
                  onTap: _showReminderPicker,
                  child: Row(
                    children: [
                      Icon(
                        Icons.notifications_active,
                        size: 16,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _formatReminderSummary(_note.reminder!),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
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
        return _buildFlatList(sortedItems, categories);
      case ChecklistDisplayMode.groupedByCategory:
        return _buildGroupedList(sortedItems, categories);
    }
  }

  Widget _buildItemTile(ChecklistItem item, List<Category> categories,
      {bool showCategory = true}) {
    return ChecklistItemTile(
      key: ValueKey(item.id),
      item: item,
      controller: _getItemController(item),
      categories: categories,
      showCategory: showCategory,
      justToggled: _justToggledItemId == item.id,
      onToggle: () => _toggleItem(item.id),
      onTextChanged: (text) => _updateItemText(item.id, text),
      onDelete: () => _removeItem(item.id),
      onCategoryChanged: (categoryId) =>
          _updateItemCategory(item.id, categoryId),
      onCreateCategory: () => _createCategoryInline(item.id),
    );
  }

  Widget _buildFlatList(List<ChecklistItem> items, List<Category> categories) {
    final displayItems = _checkedAtBottom ? _applySorting(items) : items;
    final hasUnchecked = items.any((i) => !i.isChecked);
    final hasChecked = items.any((i) => i.isChecked && i.id != _pendingMoveItemId);
    final showSeparator = _checkedAtBottom && hasUnchecked && hasChecked;

    final widgets = <Widget>[];
    var separatorAdded = false;
    for (final item in displayItems) {
      if (showSeparator && !separatorAdded &&
          item.isChecked && item.id != _pendingMoveItemId) {
        widgets.add(const CheckedSeparator());
        separatorAdded = true;
      }
      widgets.add(_buildItemTile(item, categories));
    }

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      children: widgets,
    );
  }

  Widget _buildGroupedList(List<ChecklistItem> sortedItems, List<Category> categories) {
    final categoryMap = {for (final c in categories) c.id: c};

    if (_checkedAtBottom) {
      final unchecked = sortedItems
          .where((i) => !i.isChecked || i.id == _pendingMoveItemId)
          .toList();
      final checked = sortedItems
          .where((i) => i.isChecked && i.id != _pendingMoveItemId)
          .toList();

      final groups = _groupByCategory(unchecked);
      final orderedKeys = _orderedCategoryKeys(groups, categories);

      final widgets = <Widget>[];
      for (final categoryId in orderedKeys) {
        final category = categoryId != null ? categoryMap[categoryId] : null;
        widgets.add(CategoryGroup(
          category: category,
          categoryId: categoryId,
          items: groups[categoryId]!,
          allCategories: categories,
          justToggledItemId: _justToggledItemId,
          getItemController: _getItemController,
          onToggle: _toggleItem,
          onTextChanged: _updateItemText,
          onDelete: _removeItem,
          onCategoryChanged: _updateItemCategory,
          onCreateCategoryInline: _createCategoryInline,
        ));
      }

      if (checked.isNotEmpty && unchecked.isNotEmpty) {
        widgets.add(const CheckedSeparator());
      }
      for (final item in checked) {
        widgets.add(_buildItemTile(item, categories, showCategory: false));
      }

      return ListView(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        children: widgets,
      );
    }

    final groups = _groupByCategory(sortedItems);
    final orderedKeys = _orderedCategoryKeys(groups, categories);

    final widgets = <Widget>[];
    for (final categoryId in orderedKeys) {
      final category = categoryId != null ? categoryMap[categoryId] : null;
      widgets.add(CategoryGroup(
        category: category,
        categoryId: categoryId,
        items: groups[categoryId]!,
        allCategories: categories,
        justToggledItemId: _justToggledItemId,
        getItemController: _getItemController,
        onToggle: _toggleItem,
        onTextChanged: _updateItemText,
        onDelete: _removeItem,
        onCategoryChanged: _updateItemCategory,
        onCreateCategoryInline: _createCategoryInline,
      ));
    }

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      children: widgets,
    );
  }

  Map<String?, List<ChecklistItem>> _groupByCategory(List<ChecklistItem> items) {
    final Map<String?, List<ChecklistItem>> groups = {};
    for (final item in items) {
      groups.putIfAbsent(item.categoryId, () => []).add(item);
    }
    return groups;
  }

  List<String?> _orderedCategoryKeys(
      Map<String?, List<ChecklistItem>> groups, List<Category> categories) {
    final orderedKeys = <String?>[];
    for (final cat in categories) {
      if (groups.containsKey(cat.id)) {
        orderedKeys.add(cat.id);
      }
    }
    for (final key in groups.keys) {
      if (key != null && !orderedKeys.contains(key)) {
        orderedKeys.add(key);
      }
    }
    if (groups.containsKey(null)) {
      orderedKeys.add(null);
    }
    return orderedKeys;
  }

  String _formatReminderSummary(Reminder reminder) {
    final dateFormat = DateFormat.yMMMd();
    final timeFormat = DateFormat.jm();
    final dateStr = dateFormat.format(reminder.dateTime);
    final timeStr = timeFormat.format(reminder.dateTime);
    final freq = reminder.frequency == ReminderFrequency.once
        ? ''
        : ' (${reminder.frequency.label})';
    return '$dateStr at $timeStr$freq';
  }

  Future<void> _createCategoryInline(String itemId) async {
    final result = await showDialog<Category>(
      context: context,
      builder: (context) => const CategoryFormDialog(),
    );
    if (result != null) {
      await ref.read(categoryListProvider.notifier).createCategory(result);
      _updateItemCategory(itemId, result.id);
    }
  }
}
