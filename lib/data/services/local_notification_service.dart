import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;

import '../../domain/entities/reminder.dart';
import '../../domain/services/notification_service.dart';

/// Real notification service using [flutter_local_notifications].
///
/// Uses a dual strategy for reliability:
/// - Platform alarm via [zonedSchedule] (works when app is killed/background)
/// - Foreground [Timer] + [show] (guaranteed when app is open)
///
/// If the scheduled time is in the past or within 5 seconds, fires immediately.
class LocalNotificationService implements NotificationService {
  final FlutterLocalNotificationsPlugin _plugin;
  final List<ScheduledNotification> _scheduled = [];
  final Map<String, Timer> _foregroundTimers = {};

  LocalNotificationService(this._plugin);

  /// Notification details for reminder alerts (high importance = heads-up).
  static const _reminderDetails = NotificationDetails(
    android: AndroidNotificationDetails(
      'checklist_reminders',
      'Checklist Reminders',
      channelDescription: 'Reminder notifications for your checklists',
      importance: Importance.high,
      priority: Priority.high,
    ),
    iOS: DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    ),
  );

  /// Notification details for confirmations (default importance).
  static const _confirmDetails = NotificationDetails(
    android: AndroidNotificationDetails(
      'reminders_confirm',
      'Reminder confirmations',
      channelDescription: 'Confirmation when a reminder is set',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
    ),
    iOS: DarwinNotificationDetails(),
  );

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
    try {
      await _scheduleReminderImpl(notification);
    } catch (e, st) {
      debugPrint('[Notif] scheduleReminder FAILED: $e\n$st');
      // Last resort: try to fire immediately so user sees something
      try {
        final id = _notificationId(notification.noteId);
        await _plugin.show(
            id, notification.title, notification.body, _confirmDetails);
      } catch (_) {}
    }
  }

  Future<void> _scheduleReminderImpl(ScheduledNotification notification) async {
    // Track internally
    _scheduled.removeWhere((n) => n.noteId == notification.noteId);
    _scheduled.add(notification);

    // Cancel any existing timer for this note
    _foregroundTimers[notification.noteId]?.cancel();
    _foregroundTimers.remove(notification.noteId);

    final id = _notificationId(notification.noteId);
    final reminder = notification.reminder;

    // Compute the target time
    var scheduledDate = tz.TZDateTime.from(reminder.dateTime, tz.local);
    final now = tz.TZDateTime.now(tz.local);

    debugPrint(
      '[Notif] scheduleReminder: '
      'target=$scheduledDate, now=$now, '
      'diff=${scheduledDate.difference(now).inSeconds}s',
    );

    if (scheduledDate.isBefore(now) || scheduledDate.isAtSameMomentAs(now)) {
      final next = reminder.nextOccurrence(from: now);
      if (next != null) {
        scheduledDate = tz.TZDateTime.from(next, tz.local);
      } else {
        // Time is past for a once-only reminder → fire immediately
        debugPrint('[Notif] Past once-only → firing NOW');
        await _plugin.show(
            id, notification.title, notification.body, _reminderDetails);
        return;
      }
    }

    // Cancel previous platform alarm
    await _plugin.cancel(id);

    final delay = scheduledDate.difference(tz.TZDateTime.now(tz.local));
    debugPrint('[Notif] "${notification.title}" in ${delay.inSeconds}s');

    // If delay is very short (< 5s), just fire immediately
    if (delay.inSeconds < 5) {
      debugPrint('[Notif] Delay < 5s → firing NOW');
      await _plugin.show(
          id, notification.title, notification.body, _reminderDetails);
      return;
    }

    // ── Strategy 1: Foreground Timer (guaranteed when app is open) ──
    _foregroundTimers[notification.noteId] = Timer(delay, () {
      debugPrint('[Notif] Timer fired for "${notification.title}"');
      _plugin.show(
          id, notification.title, notification.body, _reminderDetails);
    });

    // ── Strategy 2: Platform alarm (works when app is backgrounded/killed) ──
    try {
      if (reminder.frequency == ReminderFrequency.once) {
        await _plugin.zonedSchedule(
          id,
          notification.title,
          notification.body,
          scheduledDate,
          _reminderDetails,
          androidScheduleMode: AndroidScheduleMode.alarmClock,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
        );
      } else {
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
            break;
        }

        await _plugin.zonedSchedule(
          id,
          notification.title,
          notification.body,
          scheduledDate,
          _reminderDetails,
          androidScheduleMode: AndroidScheduleMode.alarmClock,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
          matchDateTimeComponents: matchComponents,
        );
      }
      debugPrint('[Notif] Platform alarm set OK');
    } catch (e, st) {
      debugPrint('[Notif] zonedSchedule FAILED: $e\n$st');
    }
  }

  @override
  Future<void> showNow({required String title, required String body}) async {
    try {
      // Use the same channel/config that was proven to work previously
      await _plugin.show(0x7FFFFFFE, title, body, _confirmDetails);
      debugPrint('[Notif] showNow OK: "$title"');
    } catch (e, st) {
      debugPrint('[Notif] showNow FAILED: $e\n$st');
    }
  }

  @override
  Future<void> cancelReminder(String noteId) async {
    _scheduled.removeWhere((n) => n.noteId == noteId);
    _foregroundTimers[noteId]?.cancel();
    _foregroundTimers.remove(noteId);
    final id = _notificationId(noteId);
    await _plugin.cancel(id);
    debugPrint('[Notif] Cancelled reminder for note $noteId');
  }

  @override
  List<ScheduledNotification> get scheduledNotifications =>
      List.unmodifiable(_scheduled);
}
