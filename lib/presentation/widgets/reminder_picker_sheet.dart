import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../domain/entities/reminder.dart';

/// Bottom sheet for setting or editing a reminder on a checklist note.
///
/// Allows the user to pick a date, time, and repeat frequency.
/// Returns a [Reminder] via [onSave], or calls [onRemove] to clear it.
class ReminderPickerSheet extends StatefulWidget {
  final Reminder? existingReminder;
  final ValueChanged<Reminder> onSave;
  final VoidCallback? onRemove;

  const ReminderPickerSheet({
    super.key,
    this.existingReminder,
    required this.onSave,
    this.onRemove,
  });

  @override
  State<ReminderPickerSheet> createState() => _ReminderPickerSheetState();
}

class _ReminderPickerSheetState extends State<ReminderPickerSheet> {
  late DateTime _selectedDate;
  late TimeOfDay _selectedTime;
  late ReminderFrequency _frequency;

  /// When the user picks a quick preset (e.g. "In 1 min"), we store the
  /// offset and recompute at save-time so the seconds aren't stale.
  Duration? _presetOffset;

  @override
  void initState() {
    super.initState();
    final existing = widget.existingReminder;
    if (existing != null) {
      _selectedDate = existing.dateTime;
      _selectedTime = TimeOfDay.fromDateTime(existing.dateTime);
      _frequency = existing.frequency;
    } else {
      // Default: tomorrow at 9:00 AM
      final tomorrow = DateTime.now().add(const Duration(days: 1));
      _selectedDate = DateTime(tomorrow.year, tomorrow.month, tomorrow.day, 9);
      _selectedTime = const TimeOfDay(hour: 9, minute: 0);
      _frequency = ReminderFrequency.once;
    }
  }

  DateTime get _combinedDateTime => DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _selectedTime.hour,
        _selectedTime.minute,
      );

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _presetOffset = null; // User manually picked, clear preset
      });
    }
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (picked != null) {
      setState(() {
        _selectedTime = picked;
        _presetOffset = null; // User manually picked, clear preset
      });
    }
  }

  void _applyPreset(Duration offset) {
    final target = DateTime.now().add(offset);
    setState(() {
      _selectedDate = target;
      _selectedTime = TimeOfDay.fromDateTime(target);
      _presetOffset = offset; // Remember offset for fresh computation on Save
    });
  }

  void _save() {
    // If a preset was used, recompute from NOW so we don't lose seconds
    // to the truncation between when the preset was tapped and Save.
    final DateTime dateTime;
    if (_presetOffset != null) {
      dateTime = DateTime.now().add(_presetOffset!);
    } else {
      dateTime = _combinedDateTime;
    }

    final reminder = Reminder(
      id: widget.existingReminder?.id ??
          'reminder-${DateTime.now().millisecondsSinceEpoch}',
      dateTime: dateTime,
      frequency: _frequency,
    );
    widget.onSave(reminder);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateFormat = DateFormat.yMMMd();
    final timeFormat = DateFormat.jm();

    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            widget.existingReminder != null ? 'Edit Reminder' : 'Set Reminder',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'All assigned persons will be notified',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 12),

          // Quick presets
          Wrap(
            spacing: 8,
            children: [
              ActionChip(
                label: const Text('In 1 min'),
                onPressed: () => _applyPreset(const Duration(minutes: 1)),
              ),
              ActionChip(
                label: const Text('In 5 min'),
                onPressed: () => _applyPreset(const Duration(minutes: 5)),
              ),
              ActionChip(
                label: const Text('In 1 hour'),
                onPressed: () => _applyPreset(const Duration(hours: 1)),
              ),
              ActionChip(
                label: const Text('Tomorrow 9 AM'),
                onPressed: () {
                  final tomorrow = DateTime.now().add(const Duration(days: 1));
                  setState(() {
                    _selectedDate = DateTime(
                        tomorrow.year, tomorrow.month, tomorrow.day, 9);
                    _selectedTime = const TimeOfDay(hour: 9, minute: 0);
                    _presetOffset = null; // Not a relative offset
                  });
                },
              ),
            ],
          ),

          const SizedBox(height: 8),

          // Date picker
          ListTile(
            leading: const Icon(Icons.calendar_today),
            title: const Text('Date'),
            trailing: Text(
              dateFormat.format(_selectedDate),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.primary,
              ),
            ),
            onTap: _pickDate,
            contentPadding: EdgeInsets.zero,
          ),

          // Time picker
          ListTile(
            leading: const Icon(Icons.access_time),
            title: const Text('Time'),
            trailing: Text(
              timeFormat.format(_combinedDateTime),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.primary,
              ),
            ),
            onTap: _pickTime,
            contentPadding: EdgeInsets.zero,
          ),

          // Frequency selector
          ListTile(
            leading: const Icon(Icons.repeat),
            title: const Text('Repeat'),
            contentPadding: EdgeInsets.zero,
            trailing: DropdownButton<ReminderFrequency>(
              value: _frequency,
              underline: const SizedBox.shrink(),
              items: ReminderFrequency.values
                  .map((f) => DropdownMenuItem(
                        value: f,
                        child: Text(f.label),
                      ))
                  .toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() => _frequency = value);
                }
              },
            ),
          ),

          const SizedBox(height: 16),

          // Action buttons
          Row(
            children: [
              if (widget.existingReminder != null && widget.onRemove != null)
                TextButton.icon(
                  onPressed: () {
                    widget.onRemove!();
                    Navigator.pop(context);
                  },
                  icon: const Icon(Icons.notifications_off_outlined),
                  label: const Text('Remove'),
                  style: TextButton.styleFrom(
                    foregroundColor: theme.colorScheme.error,
                  ),
                ),
              const Spacer(),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              const SizedBox(width: 8),
              FilledButton.icon(
                onPressed: _save,
                icon: const Icon(Icons.notifications_active, size: 18),
                label: const Text('Save'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
