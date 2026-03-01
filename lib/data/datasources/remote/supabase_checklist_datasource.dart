import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../domain/entities/checklist_item.dart';
import '../../../domain/entities/checklist_note.dart';
import '../../../domain/entities/reminder.dart';
import '../checklist_datasource.dart';

/// Supabase implementation of [ChecklistDataSource].
///
/// Notes are fetched with reminders, items and assignees in a single query
/// using PostgREST nested selects. Writes fan out to multiple tables.
class SupabaseChecklistDataSource implements ChecklistDataSource {
  final SupabaseClient _client;

  SupabaseChecklistDataSource(this._client);

  // ---------------------------------------------------------------------------
  // Parsing helpers
  // ---------------------------------------------------------------------------

  static ChecklistItem _itemFromJson(Map<String, dynamic> json) => ChecklistItem(
        id: json['id'] as String,
        text: json['text'] as String,
        isChecked: json['is_checked'] as bool,
        dueDate: json['due_date'] != null
            ? DateTime.parse(json['due_date'] as String)
            : null,
        reminderDateTime: json['reminder_date_time'] != null
            ? DateTime.parse(json['reminder_date_time'] as String)
            : null,
        order: json['order'] as int,
        categoryId: json['category_id'] as String?,
      );

  static Reminder _reminderFromJson(Map<String, dynamic> json) => Reminder(
        id: json['id'] as String,
        dateTime: DateTime.parse(json['date_time'] as String),
        frequency: ReminderFrequency.values
            .firstWhere((f) => f.name == json['frequency'] as String),
        isEnabled: json['is_enabled'] as bool,
      );

  static ChecklistNote _noteFromJson(Map<String, dynamic> json) {
    final reminderJson = json['reminders'] as Map<String, dynamic>?;
    final itemsJson = (json['checklist_items'] as List<dynamic>?) ?? [];
    final assigneesJson = (json['note_assignees'] as List<dynamic>?) ?? [];
    return ChecklistNote(
      id: json['id'] as String,
      title: json['title'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      isPinned: json['is_pinned'] as bool,
      creatorId: json['creator_id'] as String?,
      assigneeIds: assigneesJson
          .map((a) => (a as Map<String, dynamic>)['actor_id'] as String)
          .toList(),
      reminder: reminderJson != null ? _reminderFromJson(reminderJson) : null,
      items: itemsJson
          .map((i) => _itemFromJson(i as Map<String, dynamic>))
          .toList(),
    );
  }

  static const _noteSelect = '''
    *,
    reminders(*),
    checklist_items(*),
    note_assignees(actor_id)
  ''';

  // ---------------------------------------------------------------------------
  // Read
  // ---------------------------------------------------------------------------

  @override
  Future<List<ChecklistNote>> getAllNotes() async {
    final data = await _client.from('checklist_notes').select(_noteSelect);
    return data.map(_noteFromJson).toList();
  }

  @override
  Future<ChecklistNote?> getNoteById(String id) async {
    final data = await _client
        .from('checklist_notes')
        .select(_noteSelect)
        .eq('id', id)
        .maybeSingle();
    return data != null ? _noteFromJson(data) : null;
  }

  // ---------------------------------------------------------------------------
  // Write helpers
  // ---------------------------------------------------------------------------

  Map<String, dynamic> _reminderToJson(Reminder r) => {
        'id': r.id,
        'date_time': r.dateTime.toIso8601String(),
        'frequency': r.frequency.name,
        'is_enabled': r.isEnabled,
      };

  List<Map<String, dynamic>> _itemsToJson(
          String noteId, List<ChecklistItem> items) =>
      items
          .map((item) => {
                'id': item.id,
                'note_id': noteId,
                'text': item.text,
                'is_checked': item.isChecked,
                'due_date': item.dueDate?.toIso8601String(),
                'reminder_date_time': item.reminderDateTime?.toIso8601String(),
                'order': item.order,
                'category_id': item.categoryId,
              })
          .toList();

  List<Map<String, dynamic>> _assigneesToJson(
          String noteId, List<String> actorIds) =>
      actorIds
          .map((actorId) => {'note_id': noteId, 'actor_id': actorId})
          .toList();

  // ---------------------------------------------------------------------------
  // Create
  // ---------------------------------------------------------------------------

  @override
  Future<ChecklistNote> createNote(ChecklistNote note) async {
    // 1. Insert reminder first so we have the id for the FK.
    if (note.reminder != null) {
      await _client.from('reminders').insert(_reminderToJson(note.reminder!));
    }

    // 2. Insert note row.
    await _client.from('checklist_notes').insert({
      'id': note.id,
      'title': note.title,
      'created_at': note.createdAt.toIso8601String(),
      'updated_at': note.updatedAt.toIso8601String(),
      'is_pinned': note.isPinned,
      'creator_id': note.creatorId,
      'reminder_id': note.reminder?.id,
    });

    // 3. Insert items.
    if (note.items.isNotEmpty) {
      await _client
          .from('checklist_items')
          .insert(_itemsToJson(note.id, note.items));
    }

    // 4. Insert assignees.
    if (note.assigneeIds.isNotEmpty) {
      await _client
          .from('note_assignees')
          .insert(_assigneesToJson(note.id, note.assigneeIds));
    }

    return note;
  }

  // ---------------------------------------------------------------------------
  // Update
  // ---------------------------------------------------------------------------

  @override
  Future<ChecklistNote> updateNote(ChecklistNote note) async {
    // 1. Upsert reminder (create or update in place).
    if (note.reminder != null) {
      await _client
          .from('reminders')
          .upsert(_reminderToJson(note.reminder!));
    }

    // 2. Update note row (reminder_id becomes null if reminder was removed).
    await _client.from('checklist_notes').update({
      'title': note.title,
      'updated_at': note.updatedAt.toIso8601String(),
      'is_pinned': note.isPinned,
      'creator_id': note.creatorId,
      'reminder_id': note.reminder?.id,
    }).eq('id', note.id);

    // 3. Replace items: delete then re-insert.
    await _client.from('checklist_items').delete().eq('note_id', note.id);
    if (note.items.isNotEmpty) {
      await _client
          .from('checklist_items')
          .insert(_itemsToJson(note.id, note.items));
    }

    // 4. Replace assignees: delete then re-insert.
    await _client.from('note_assignees').delete().eq('note_id', note.id);
    if (note.assigneeIds.isNotEmpty) {
      await _client
          .from('note_assignees')
          .insert(_assigneesToJson(note.id, note.assigneeIds));
    }

    return note;
  }

  // ---------------------------------------------------------------------------
  // Delete
  // ---------------------------------------------------------------------------

  @override
  Future<void> deleteNote(String id) async {
    // Fetch reminder_id before deleting — the reminder won't cascade.
    final row = await _client
        .from('checklist_notes')
        .select('reminder_id')
        .eq('id', id)
        .maybeSingle();
    final reminderId = row?['reminder_id'] as String?;

    // Delete note; checklist_items and note_assignees cascade automatically.
    await _client.from('checklist_notes').delete().eq('id', id);

    // Clean up the now-orphan reminder.
    if (reminderId != null) {
      await _client.from('reminders').delete().eq('id', reminderId);
    }
  }
}
