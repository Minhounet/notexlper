import 'package:flutter/foundation.dart';

import '../../domain/services/notification_service.dart';

/// In-memory notification service for development and testing.
///
/// Logs scheduled notifications to the debug console.
/// In production, this would be replaced with a real notification
/// service using flutter_local_notifications or Firebase Cloud Messaging.
class FakeNotificationService implements NotificationService {
  final List<ScheduledNotification> _scheduled = [];

  @override
  Future<void> scheduleReminder(ScheduledNotification notification) async {
    // Remove any existing notification for the same note
    _scheduled.removeWhere((n) => n.noteId == notification.noteId);
    _scheduled.add(notification);
    debugPrint(
      '[FakeNotificationService] Scheduled reminder for "${notification.title}" '
      'at ${notification.reminder.dateTime} '
      '(${notification.reminder.frequency.label}) '
      'for ${notification.recipientIds.length} recipient(s)',
    );
  }

  @override
  Future<void> cancelReminder(String noteId) async {
    _scheduled.removeWhere((n) => n.noteId == noteId);
    debugPrint('[FakeNotificationService] Cancelled reminder for note $noteId');
  }

  @override
  List<ScheduledNotification> get scheduledNotifications =>
      List.unmodifiable(_scheduled);
}
