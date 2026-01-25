import 'package:equatable/equatable.dart';

/// Represents a single item in a checklist.
class ChecklistItem extends Equatable {
  final String id;
  final String text;
  final bool isChecked;
  final DateTime? dueDate;
  final DateTime? reminderDateTime;
  final int order;

  const ChecklistItem({
    required this.id,
    required this.text,
    this.isChecked = false,
    this.dueDate,
    this.reminderDateTime,
    this.order = 0,
  });

  ChecklistItem copyWith({
    String? id,
    String? text,
    bool? isChecked,
    DateTime? dueDate,
    DateTime? reminderDateTime,
    int? order,
  }) {
    return ChecklistItem(
      id: id ?? this.id,
      text: text ?? this.text,
      isChecked: isChecked ?? this.isChecked,
      dueDate: dueDate ?? this.dueDate,
      reminderDateTime: reminderDateTime ?? this.reminderDateTime,
      order: order ?? this.order,
    );
  }

  @override
  List<Object?> get props => [
        id,
        text,
        isChecked,
        dueDate,
        reminderDateTime,
        order,
      ];
}
