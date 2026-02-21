import 'package:equatable/equatable.dart';

/// The frequency at which a reminder repeats.
enum ReminderFrequency {
  once,
  daily,
  weekly,
  monthly;

  String get label {
    switch (this) {
      case ReminderFrequency.once:
        return 'Once';
      case ReminderFrequency.daily:
        return 'Daily';
      case ReminderFrequency.weekly:
        return 'Weekly';
      case ReminderFrequency.monthly:
        return 'Monthly';
    }
  }
}

/// A reminder attached to a checklist note.
///
/// Specifies when the first notification fires ([dateTime]),
/// how often it repeats ([frequency]), and whether it is active
/// ([isEnabled]). All assigned persons on the note should be notified.
class Reminder extends Equatable {
  final String id;
  final DateTime dateTime;
  final ReminderFrequency frequency;
  final bool isEnabled;

  const Reminder({
    required this.id,
    required this.dateTime,
    this.frequency = ReminderFrequency.once,
    this.isEnabled = true,
  });

  Reminder copyWith({
    String? id,
    DateTime? dateTime,
    ReminderFrequency? frequency,
    bool? isEnabled,
  }) {
    return Reminder(
      id: id ?? this.id,
      dateTime: dateTime ?? this.dateTime,
      frequency: frequency ?? this.frequency,
      isEnabled: isEnabled ?? this.isEnabled,
    );
  }

  /// Computes the next occurrence after [from] based on [frequency].
  /// Returns `null` for one-time reminders that are already past.
  DateTime? nextOccurrence({DateTime? from}) {
    final now = from ?? DateTime.now();
    if (dateTime.isAfter(now)) return dateTime;

    switch (frequency) {
      case ReminderFrequency.once:
        return null; // Already past
      case ReminderFrequency.daily:
        var next = dateTime;
        while (!next.isAfter(now)) {
          next = next.add(const Duration(days: 1));
        }
        return next;
      case ReminderFrequency.weekly:
        var next = dateTime;
        while (!next.isAfter(now)) {
          next = next.add(const Duration(days: 7));
        }
        return next;
      case ReminderFrequency.monthly:
        var next = dateTime;
        while (!next.isAfter(now)) {
          next = DateTime(next.year, next.month + 1, next.day,
              next.hour, next.minute);
        }
        return next;
    }
  }

  @override
  List<Object?> get props => [id, dateTime, frequency, isEnabled];
}
