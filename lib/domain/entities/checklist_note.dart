import 'package:equatable/equatable.dart';

import 'checklist_item.dart';

/// Represents a checklist note containing multiple items.
class ChecklistNote extends Equatable {
  final String id;
  final String title;
  final List<ChecklistItem> items;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isPinned;

  const ChecklistNote({
    required this.id,
    required this.title,
    required this.items,
    required this.createdAt,
    required this.updatedAt,
    this.isPinned = false,
  });

  /// Returns the count of completed items
  int get completedCount => items.where((item) => item.isChecked).length;

  /// Returns the total count of items
  int get totalCount => items.length;

  /// Returns true if all items are checked
  bool get isCompleted => items.isNotEmpty && completedCount == totalCount;

  /// Returns items sorted by their order
  List<ChecklistItem> get sortedItems =>
      List.from(items)..sort((a, b) => a.order.compareTo(b.order));

  ChecklistNote copyWith({
    String? id,
    String? title,
    List<ChecklistItem>? items,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isPinned,
  }) {
    return ChecklistNote(
      id: id ?? this.id,
      title: title ?? this.title,
      items: items ?? this.items,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isPinned: isPinned ?? this.isPinned,
    );
  }

  @override
  List<Object?> get props => [
        id,
        title,
        items,
        createdAt,
        updatedAt,
        isPinned,
      ];
}
