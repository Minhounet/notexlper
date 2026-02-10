import 'package:flutter_test/flutter_test.dart';
import 'package:notexlper/domain/entities/reminder.dart';

void main() {
  group('Reminder', () {
    final baseDate = DateTime(2025, 6, 15, 9, 0);

    test('should create a one-time reminder by default', () {
      final reminder = Reminder(
        id: 'r-1',
        dateTime: baseDate,
      );

      expect(reminder.frequency, ReminderFrequency.once);
      expect(reminder.isEnabled, true);
      expect(reminder.dateTime, baseDate);
    });

    test('should create a recurring reminder with specified frequency', () {
      final reminder = Reminder(
        id: 'r-1',
        dateTime: baseDate,
        frequency: ReminderFrequency.weekly,
      );

      expect(reminder.frequency, ReminderFrequency.weekly);
    });

    test('copyWith should update fields', () {
      final reminder = Reminder(
        id: 'r-1',
        dateTime: baseDate,
        frequency: ReminderFrequency.once,
      );

      final updated = reminder.copyWith(
        frequency: ReminderFrequency.daily,
        isEnabled: false,
      );

      expect(updated.frequency, ReminderFrequency.daily);
      expect(updated.isEnabled, false);
      expect(updated.id, 'r-1');
      expect(updated.dateTime, baseDate);
    });

    test('two reminders with same properties should be equal', () {
      final r1 = Reminder(id: 'r-1', dateTime: baseDate);
      final r2 = Reminder(id: 'r-1', dateTime: baseDate);

      expect(r1, r2);
    });

    test('reminders with different properties should not be equal', () {
      final r1 = Reminder(id: 'r-1', dateTime: baseDate);
      final r2 = Reminder(
        id: 'r-1',
        dateTime: baseDate,
        frequency: ReminderFrequency.daily,
      );

      expect(r1, isNot(r2));
    });
  });

  group('ReminderFrequency', () {
    test('label should return correct strings', () {
      expect(ReminderFrequency.once.label, 'Once');
      expect(ReminderFrequency.daily.label, 'Daily');
      expect(ReminderFrequency.weekly.label, 'Weekly');
      expect(ReminderFrequency.monthly.label, 'Monthly');
    });
  });

  group('Reminder.nextOccurrence', () {
    test('should return dateTime if it is in the future', () {
      final futureDate = DateTime.now().add(const Duration(days: 10));
      final reminder = Reminder(id: 'r-1', dateTime: futureDate);

      final next = reminder.nextOccurrence();

      expect(next, futureDate);
    });

    test('should return null for past one-time reminder', () {
      final pastDate = DateTime(2020, 1, 1, 9, 0);
      final reminder = Reminder(id: 'r-1', dateTime: pastDate);

      final next = reminder.nextOccurrence();

      expect(next, isNull);
    });

    test('should return next daily occurrence after now', () {
      final pastDate = DateTime(2020, 1, 1, 9, 0);
      final now = DateTime(2025, 6, 15, 10, 0);
      final reminder = Reminder(
        id: 'r-1',
        dateTime: pastDate,
        frequency: ReminderFrequency.daily,
      );

      final next = reminder.nextOccurrence(from: now);

      expect(next, isNotNull);
      expect(next!.isAfter(now), true);
      expect(next.hour, 9);
      expect(next.minute, 0);
    });

    test('should return next weekly occurrence after now', () {
      final pastDate = DateTime(2025, 6, 1, 9, 0); // Sunday
      final now = DateTime(2025, 6, 15, 10, 0);
      final reminder = Reminder(
        id: 'r-1',
        dateTime: pastDate,
        frequency: ReminderFrequency.weekly,
      );

      final next = reminder.nextOccurrence(from: now);

      expect(next, isNotNull);
      expect(next!.isAfter(now), true);
      // Should be a multiple of 7 days after pastDate
      expect(next.difference(pastDate).inDays % 7, 0);
    });

    test('should return next monthly occurrence after now', () {
      final pastDate = DateTime(2025, 1, 15, 9, 0);
      final now = DateTime(2025, 6, 15, 10, 0);
      final reminder = Reminder(
        id: 'r-1',
        dateTime: pastDate,
        frequency: ReminderFrequency.monthly,
      );

      final next = reminder.nextOccurrence(from: now);

      expect(next, isNotNull);
      expect(next!.isAfter(now), true);
      expect(next.day, 15);
      expect(next.hour, 9);
    });
  });
}
