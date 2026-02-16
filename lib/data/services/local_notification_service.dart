import 'dart:async';
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
///
/// Uses a dual strategy for reliability:
/// - Platform alarm via [zonedSchedule] (works when app is killed/background)
/// - Foreground [Timer] via [show] (guaranteed when app is open)
class LocalNotificationService implements NotificationService {
  final FlutterLocalNotificationsPlugin _plugin;
  final List<ScheduledNotification> _scheduled = [];
  Timer? _foregroundTimer;

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

    // Cancel any existing foreground timer
    _foregroundTimer?.cancel();
    _foregroundTimer = null;

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

    // Ensure the scheduled time is in the future
    var scheduledDate = tz.TZDateTime.from(reminder.dateTime, tz.local);
    final now = tz.TZDateTime.now(tz.local);
    if (scheduledDate.isBefore(now) || scheduledDate.isAtSameMomentAs(now)) {
      // For recurring reminders, advance to the next occurrence
      final next = reminder.nextOccurrence(from: now);
      if (next != null) {
        scheduledDate = tz.TZDateTime.from(next, tz.local);
      } else {
        debugPrint(
          '[Notif] SKIP: scheduled time ${reminder.dateTime} is in the past',
        );
        return;
      }
    }

    // Cancel previous platform alarm for this note
    await _plugin.cancel(id);

    final delay = scheduledDate.difference(now);
    debugPrint(
      '[Notif] Scheduling "${notification.title}" in ${delay.inSeconds}s '
      '(at $scheduledDate, mode=${reminder.frequency.label})',
    );

    // ── Strategy 1: Foreground Timer (guaranteed when app is open) ──
    // Always set a Dart-side timer so the notification fires even if
    // Android's alarm system drops or delays it.
    _foregroundTimer = Timer(delay, () {
      debugPrint('[Notif] Foreground timer fired for "${notification.title}"');
      _plugin.show(
        id,
        notification.title,
        notification.body,
        details,
      );
    });

    // ── Strategy 2: Platform alarm (works when app is backgrounded/killed) ──
    try {
      if (reminder.frequency == ReminderFrequency.once) {
        await _plugin.zonedSchedule(
          id,
          notification.title,
          notification.body,
          scheduledDate,
          details,
          androidScheduleMode: AndroidScheduleMode.alarmClock,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
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
          androidScheduleMode: AndroidScheduleMode.alarmClock,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
          matchDateTimeComponents: matchComponents,
        );
      }
      debugPrint('[Notif] Platform alarm set OK');
    } catch (e, st) {
      debugPrint('[Notif] zonedSchedule FAILED: $e\n$st');
      // Foreground timer is already set as fallback, so the user will
      // still get the notification if the app stays open.
    }
  }

  @override
  Future<void> showNow({required String title, required String body}) async {
    const androidDetails = AndroidNotificationDetails(
      'reminders_confirm',
      'Reminder confirmations',
      channelDescription: 'Confirmation when a reminder is set',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
    );
    const iosDetails = DarwinNotificationDetails();
    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    // Use a fixed high ID so confirmation notifications don't clash with scheduled ones
    await _plugin.show(0x7FFFFFFE, title, body, details);
  }

  @override
  Future<void> cancelReminder(String noteId) async {
    _scheduled.removeWhere((n) => n.noteId == noteId);
    _foregroundTimer?.cancel();
    _foregroundTimer = null;
    final id = _notificationId(noteId);
    await _plugin.cancel(id);
    debugPrint('[Notif] Cancelled reminder for note $noteId');
  }

  @override
  List<ScheduledNotification> get scheduledNotifications =>
      List.unmodifiable(_scheduled);
}
