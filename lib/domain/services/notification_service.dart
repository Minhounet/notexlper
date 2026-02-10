import '../entities/reminder.dart';

/// Scheduled notification payload used by [NotificationService].
class ScheduledNotification {
  final String noteId;
  final String title;
  final String body;
  final List<String> recipientIds;
  final Reminder reminder;

  const ScheduledNotification({
    required this.noteId,
    required this.title,
    required this.body,
    required this.recipientIds,
    required this.reminder,
  });
}

/// Abstract notification service for scheduling reminders.
///
/// In dev mode, use [FakeNotificationService].
/// In prod, implement with flutter_local_notifications + push notifications.
abstract class NotificationService {
  /// Schedules a notification for the given reminder.
  /// [recipientIds] are the actor IDs that should be notified.
  Future<void> scheduleReminder(ScheduledNotification notification);

  /// Cancels all notifications for the given note.
  Future<void> cancelReminder(String noteId);

  /// Returns all currently scheduled notifications (for debugging/testing).
  List<ScheduledNotification> get scheduledNotifications;
}
