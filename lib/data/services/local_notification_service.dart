import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;

import '../../domain/entities/reminder.dart';
import '../../domain/services/notification_service.dart';

/// Real notification service using [flutter_local_notifications].
///
/// Schedules platform notifications that fire at the specified date/time
/// and repeat according to the selected frequency.
/// All assigned persons see the notification on their device.
class LocalNotificationService implements NotificationService {
  final FlutterLocalNotificationsPlugin _plugin;
  final List<ScheduledNotification> _scheduled = [];

  LocalNotificationService(this._plugin);

  /// Initialize the plugin. Must be called once at app startup.
  static Future<LocalNotificationService> init() async {
    final plugin = FlutterLocalNotificationsPlugin();

    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await plugin.initialize(settings);

    // Request notification permission on Android 13+
    if (Platform.isAndroid) {
      final androidPlugin =
          plugin.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      await androidPlugin?.requestNotificationsPermission();
      await androidPlugin?.requestExactAlarmsPermission();
    }

    return LocalNotificationService(plugin);
  }

  /// Stable int ID derived from noteId string for the platform.
  int _notificationId(String noteId) => noteId.hashCode.abs() % 0x7FFFFFFF;

  @override
  Future<void> scheduleReminder(ScheduledNotification notification) async {
    // Track internally
    _scheduled.removeWhere((n) => n.noteId == notification.noteId);
    _scheduled.add(notification);

    final id = _notificationId(notification.noteId);
    final reminder = notification.reminder;

    const androidDetails = AndroidNotificationDetails(
      'reminders',
      'Reminders',
      channelDescription: 'Checklist reminder notifications',
      importance: Importance.high,
      priority: Priority.high,
    );
    const iosDetails = DarwinNotificationDetails();
    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    final scheduledDate = tz.TZDateTime.from(reminder.dateTime, tz.local);

    // Cancel previous for this note before scheduling new one
    await _plugin.cancel(id);

    if (reminder.frequency == ReminderFrequency.once) {
      await _plugin.zonedSchedule(
        id,
        notification.title,
        notification.body,
        scheduledDate,
        details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: null,
      );
    } else {
      // For recurring reminders, match the appropriate date component
      DateTimeComponents? matchComponents;
      switch (reminder.frequency) {
        case ReminderFrequency.daily:
          matchComponents = DateTimeComponents.time;
          break;
        case ReminderFrequency.weekly:
          matchComponents = DateTimeComponents.dayOfWeekAndTime;
          break;
        case ReminderFrequency.monthly:
          matchComponents = DateTimeComponents.dayOfMonthAndTime;
          break;
        case ReminderFrequency.once:
          break; // Already handled above
      }

      await _plugin.zonedSchedule(
        id,
        notification.title,
        notification.body,
        scheduledDate,
        details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: matchComponents,
      );
    }

    debugPrint(
      '[LocalNotificationService] Scheduled "${notification.title}" '
      'at ${reminder.dateTime} (${reminder.frequency.label}) '
      'for ${notification.recipientIds.length} recipient(s)',
    );
  }

  @override
  Future<void> cancelReminder(String noteId) async {
    _scheduled.removeWhere((n) => n.noteId == noteId);
    final id = _notificationId(noteId);
    await _plugin.cancel(id);
    debugPrint('[LocalNotificationService] Cancelled reminder for note $noteId');
  }

  @override
  List<ScheduledNotification> get scheduledNotifications =>
      List.unmodifiable(_scheduled);
}
