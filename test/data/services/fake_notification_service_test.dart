import 'package:flutter_test/flutter_test.dart';
import 'package:notexlper/data/services/fake_notification_service.dart';
import 'package:notexlper/domain/entities/reminder.dart';
import 'package:notexlper/domain/services/notification_service.dart';

void main() {
  late FakeNotificationService service;

  setUp(() {
    service = FakeNotificationService();
  });

  group('FakeNotificationService', () {
    test('should start with no scheduled notifications', () {
      expect(service.scheduledNotifications, isEmpty);
    });

    test('should schedule a notification', () async {
      final reminder = Reminder(
        id: 'r-1',
        dateTime: DateTime(2025, 6, 15, 9, 0),
        frequency: ReminderFrequency.daily,
      );

      await service.scheduleReminder(ScheduledNotification(
        noteId: 'note-1',
        title: 'Test Checklist',
        body: '3 items remaining',
        recipientIds: ['actor-1', 'actor-2'],
        reminder: reminder,
      ));

      expect(service.scheduledNotifications, hasLength(1));
      expect(service.scheduledNotifications.first.noteId, 'note-1');
      expect(service.scheduledNotifications.first.recipientIds, hasLength(2));
    });

    test('should replace existing notification for same note', () async {
      final reminder1 = Reminder(
        id: 'r-1',
        dateTime: DateTime(2025, 6, 15, 9, 0),
      );
      final reminder2 = Reminder(
        id: 'r-2',
        dateTime: DateTime(2025, 6, 16, 10, 0),
      );

      await service.scheduleReminder(ScheduledNotification(
        noteId: 'note-1',
        title: 'First',
        body: 'body',
        recipientIds: ['actor-1'],
        reminder: reminder1,
      ));

      await service.scheduleReminder(ScheduledNotification(
        noteId: 'note-1',
        title: 'Updated',
        body: 'body',
        recipientIds: ['actor-1'],
        reminder: reminder2,
      ));

      expect(service.scheduledNotifications, hasLength(1));
      expect(service.scheduledNotifications.first.title, 'Updated');
    });

    test('should cancel a notification', () async {
      final reminder = Reminder(
        id: 'r-1',
        dateTime: DateTime(2025, 6, 15, 9, 0),
      );

      await service.scheduleReminder(ScheduledNotification(
        noteId: 'note-1',
        title: 'Test',
        body: 'body',
        recipientIds: ['actor-1'],
        reminder: reminder,
      ));

      expect(service.scheduledNotifications, hasLength(1));

      await service.cancelReminder('note-1');

      expect(service.scheduledNotifications, isEmpty);
    });

    test('cancelling non-existent note should not throw', () async {
      await service.cancelReminder('non-existent');

      expect(service.scheduledNotifications, isEmpty);
    });
  });
}
