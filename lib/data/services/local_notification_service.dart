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
/// - Foreground [Timer] + [show] (guaranteed when app is open)
/// - Platform alarm via [zonedSchedule] (works when app is killed/background)
///
/// If the scheduled time is in the past or within 5 seconds, fires immediately.
class LocalNotificationService implements NotificationService {
  final FlutterLocalNotificationsPlugin _plugin;
  final List<ScheduledNotification> _scheduled = [];
  final Map<String, Timer> _foregroundTimers = {};

  LocalNotificationService(this._plugin);

  /// Single notification config used for ALL notifications.
  /// Using the same channel that showNow() uses (proven to work)
  /// avoids Android notification channel caching issues.
  static const _details = NotificationDetails(
    android: AndroidNotificationDetails(
      'reminders_confirm',
      'Reminder confirmations',
      channelDescription: 'Checklist reminder notifications',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
    ),
    iOS: DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    ),
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
    _scheduled.removeWhere((n) => n.noteId == notification.noteId);
    _scheduled.add(notification);

    // Cancel any existing timer for this note
    _foregroundTimers[notification.noteId]?.cancel();
    _foregroundTimers.remove(notification.noteId);

    final id = _notificationId(notification.noteId);
    final target = notification.reminder.dateTime;

    // Use plain DateTime for delay — no timezone conversion, no risk of error.
    // Both target and now are local time, so difference() is correct.
    final now = DateTime.now();
    final delay = target.difference(now);

    debugPrint(
      '[Notif] schedule: target=$target, now=$now, '
      'delay=${delay.inSeconds}s, freq=${notification.reminder.frequency.label}',
    );

    // If time is past or imminent (<= 5s), fire immediately
    if (delay.inSeconds <= 5) {
      debugPrint('[Notif] Delay <= 5s → firing immediately');
      try {
        await _plugin.show(
            id, notification.title, notification.body, _details);
      } catch (e) {
        debugPrint('[Notif] Immediate show() failed: $e');
      }
      return;
    }

    // ── Strategy 1: Foreground Timer (guaranteed when app is open) ──
    // Set BEFORE any async operations so it can never be skipped by an error.
    _foregroundTimers[notification.noteId] = Timer(delay, () {
      debugPrint('[Notif] TIMER FIRED for "${notification.title}"');
      _plugin.show(id, notification.title, notification.body, _details);
    });
    debugPrint('[Notif] Foreground timer set for ${delay.inSeconds}s');

    // ── Strategy 2: Platform alarm (best-effort, for when app is killed) ──
    _tryPlatformAlarm(notification, id);
  }

  /// Attempt to set a platform alarm via zonedSchedule.
  /// This is best-effort — if it fails, the foreground Timer is the fallback.
  Future<void> _tryPlatformAlarm(
      ScheduledNotification notification, int id) async {
    try {
      await _plugin.cancel(id);

      final reminder = notification.reminder;
      final scheduledDate = tz.TZDateTime.from(reminder.dateTime, tz.local);

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
          matchComponents = null;
          break;
      }

      await _plugin.zonedSchedule(
        id,
        notification.title,
        notification.body,
        scheduledDate,
        _details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: matchComponents,
      );
      debugPrint('[Notif] Platform alarm set OK');
    } catch (e) {
      debugPrint('[Notif] Platform alarm failed (Timer is fallback): $e');
    }
  }

  @override
  Future<void> showNow({required String title, required String body}) async {
    try {
      await _plugin.show(0x7FFFFFFE, title, body, _details);
      debugPrint('[Notif] showNow OK');
    } catch (e) {
      debugPrint('[Notif] showNow failed: $e');
    }
  }

  @override
  Future<void> cancelReminder(String noteId) async {
    _scheduled.removeWhere((n) => n.noteId == noteId);
    _foregroundTimers[noteId]?.cancel();
    _foregroundTimers.remove(noteId);
    final id = _notificationId(noteId);
    await _plugin.cancel(id);
    debugPrint('[Notif] Cancelled reminder for $noteId');
  }

  @override
  List<ScheduledNotification> get scheduledNotifications =>
      List.unmodifiable(_scheduled);
}
