import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notexlper/domain/entities/reminder.dart';
import 'package:notexlper/presentation/widgets/reminder_picker_sheet.dart';

void main() {
  group('ReminderPickerSheet', () {
    Widget createSheet({
      Reminder? existingReminder,
      required ValueChanged<Reminder> onSave,
      VoidCallback? onRemove,
    }) {
      return MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  builder: (_) => ReminderPickerSheet(
                    existingReminder: existingReminder,
                    onSave: onSave,
                    onRemove: onRemove,
                  ),
                );
              },
              child: const Text('Open'),
            ),
          ),
        ),
      );
    }

    testWidgets('should show Set Reminder title for new reminder',
        (tester) async {
      await tester.pumpWidget(createSheet(
        onSave: (_) {},
      ));

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.text('Set Reminder'), findsOneWidget);
      expect(find.text('All assigned persons will be notified'), findsOneWidget);
    });

    testWidgets('should show Edit Reminder title for existing reminder',
        (tester) async {
      final existing = Reminder(
        id: 'r-1',
        dateTime: DateTime(2025, 6, 15, 9, 0),
        frequency: ReminderFrequency.weekly,
      );

      await tester.pumpWidget(createSheet(
        existingReminder: existing,
        onSave: (_) {},
        onRemove: () {},
      ));

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.text('Edit Reminder'), findsOneWidget);
    });

    testWidgets('should show Remove button only when editing existing reminder',
        (tester) async {
      // New reminder - no Remove button
      await tester.pumpWidget(createSheet(onSave: (_) {}));
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.text('Remove'), findsNothing);
    });

    testWidgets('should show Remove button for existing reminder',
        (tester) async {
      final existing = Reminder(
        id: 'r-1',
        dateTime: DateTime(2025, 6, 15, 9, 0),
      );

      await tester.pumpWidget(createSheet(
        existingReminder: existing,
        onSave: (_) {},
        onRemove: () {},
      ));

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.text('Remove'), findsOneWidget);
    });

    testWidgets('should show date, time, and frequency controls',
        (tester) async {
      await tester.pumpWidget(createSheet(onSave: (_) {}));
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.text('Date'), findsOneWidget);
      expect(find.text('Time'), findsOneWidget);
      expect(find.text('Repeat'), findsOneWidget);
      expect(find.text('Once'), findsOneWidget); // Default frequency
    });

    testWidgets('should show frequency dropdown with all options',
        (tester) async {
      await tester.pumpWidget(createSheet(onSave: (_) {}));
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      // Tap the dropdown
      await tester.tap(find.text('Once'));
      await tester.pumpAndSettle();

      expect(find.text('Daily'), findsOneWidget);
      expect(find.text('Weekly'), findsOneWidget);
      expect(find.text('Monthly'), findsOneWidget);
    });

    testWidgets('should call onSave with reminder when Save is tapped',
        (tester) async {
      Reminder? savedReminder;
      await tester.pumpWidget(createSheet(
        onSave: (r) => savedReminder = r,
      ));

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(savedReminder, isNotNull);
      expect(savedReminder!.frequency, ReminderFrequency.once);
      expect(savedReminder!.isEnabled, true);
    });

    testWidgets('should close when Cancel is tapped', (tester) async {
      Reminder? savedReminder;
      await tester.pumpWidget(createSheet(
        onSave: (r) => savedReminder = r,
      ));

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(savedReminder, isNull);
      expect(find.text('Set Reminder'), findsNothing);
    });

    testWidgets('should call onRemove when Remove is tapped', (tester) async {
      var removed = false;
      final existing = Reminder(
        id: 'r-1',
        dateTime: DateTime(2025, 6, 15, 9, 0),
      );

      await tester.pumpWidget(createSheet(
        existingReminder: existing,
        onSave: (_) {},
        onRemove: () => removed = true,
      ));

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Remove'));
      await tester.pumpAndSettle();

      expect(removed, true);
    });
  });
}
