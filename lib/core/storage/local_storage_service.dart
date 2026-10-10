import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../features/auth/models/user.dart';
import '../../features/events/models/event.dart';
import '../../features/notes/models/note.dart';
import '../../features/tasks/models/task.dart';

final localStorageServiceProvider = Provider<LocalStorageService>((ref) {
  return LocalStorageService();
});

class LocalStorageService {
  static const String tasksBoxName = 'detailed_todo_tasks';
  static const String notesBoxName = 'detailed_todo_notes';
  static const String eventsBoxName = 'detailed_todo_events';
  static const String syncQueueBoxName = 'detailed_todo_sync_queue';
  static const String userBoxName = 'detailed_todo_user';

  static Future<void> init() async {
    await Hive.initFlutter();
    await Future.wait([
      Hive.openBox<Map>(tasksBoxName),
      Hive.openBox<Map>(notesBoxName),
      Hive.openBox<Map>(eventsBoxName),
      Hive.openBox<Map>(syncQueueBoxName),
      Hive.openBox<Map>(userBoxName),
    ]);
  }

  Box<Map> get _tasksBox => Hive.box<Map>(tasksBoxName);
  Box<Map> get _notesBox => Hive.box<Map>(notesBoxName);
  Box<Map> get _eventsBox => Hive.box<Map>(eventsBoxName);
  Box<Map> get _syncQueueBox => Hive.box<Map>(syncQueueBoxName);
  Box<Map> get _userBox => Hive.box<Map>(userBoxName);

  // ===================== USER =====================

  User? getUser() {
    final raw = _userBox.get('current_user');
    if (raw == null) return null;
    return User.fromJson(Map<String, dynamic>.from(raw));
  }

  Future<void> saveUser(User user) async {
    await _userBox.put('current_user', user.toJson());
  }

  Future<void> deleteUser() async {
    await _userBox.delete('current_user');
  }

  // ===================== TASKS =====================

  List<Task> getTasks({
    String? status,
    String? priority,
    String? folder,
    String? tag,
  }) {
    final list = _tasksBox.values
        .map((e) => Task.fromJson(Map<String, dynamic>.from(e)))
        .toList();

    return list.where((t) {
      if (status != null && t.status.value.toUpperCase() != status.toUpperCase()) {
        return false;
      }
      if (priority != null && t.priority.value.toUpperCase() != priority.toUpperCase()) {
        return false;
      }
      if (folder != null && folder.isNotEmpty && t.folder != folder) {
        return false;
      }
      if (tag != null && tag.isNotEmpty && !t.tags.contains(tag)) {
        return false;
      }
      return true;
    }).toList()
      ..sort((a, b) {
        final aDate = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bDate = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        return bDate.compareTo(aDate);
      });
  }

  Task? getTask(String id) {
    final raw = _tasksBox.get(id);
    if (raw == null) return null;
    return Task.fromJson(Map<String, dynamic>.from(raw));
  }

  Future<void> saveTask(Task task) async {
    await _tasksBox.put(task.id, task.toJson());
  }

  Future<void> saveTasks(List<Task> tasks) async {
    final entries = <String, Map<String, dynamic>>{
      for (final t in tasks) t.id: t.toJson(),
    };
    await _tasksBox.putAll(entries);
  }

  Future<void> deleteTask(String id) async {
    await _tasksBox.delete(id);
  }

  // ===================== NOTES =====================

  List<Note> getNotes({
    String? folder,
    String? tag,
  }) {
    final list = _notesBox.values
        .map((e) => Note.fromJson(Map<String, dynamic>.from(e)))
        .toList();

    return list.where((n) {
      if (folder != null && folder.isNotEmpty && n.folder != folder) {
        return false;
      }
      if (tag != null && tag.isNotEmpty && !n.tags.contains(tag)) {
        return false;
      }
      return true;
    }).toList()
      ..sort((a, b) {
        final aDate = a.updatedAt ?? a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bDate = b.updatedAt ?? b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        return bDate.compareTo(aDate);
      });
  }

  Note? getNote(String id) {
    final raw = _notesBox.get(id);
    if (raw == null) return null;
    return Note.fromJson(Map<String, dynamic>.from(raw));
  }

  Future<void> saveNote(Note note) async {
    await _notesBox.put(note.id, note.toJson());
  }

  Future<void> saveNotes(List<Note> notes) async {
    final entries = <String, Map<String, dynamic>>{
      for (final n in notes) n.id: n.toJson(),
    };
    await _notesBox.putAll(entries);
  }

  Future<void> deleteNote(String id) async {
    await _notesBox.delete(id);
  }

  // ===================== EVENTS =====================

  List<Event> getEvents({
    DateTime? from,
    DateTime? to,
  }) {
    final list = _eventsBox.values
        .map((e) => Event.fromJson(Map<String, dynamic>.from(e)))
        .toList();

    return list.where((e) {
      if (from != null && e.startDate.isBefore(from)) {
        return false;
      }
      if (to != null && e.startDate.isAfter(to)) {
        return false;
      }
      return true;
    }).toList()
      ..sort((a, b) => a.startDate.compareTo(b.startDate));
  }

  Event? getEvent(String id) {
    final raw = _eventsBox.get(id);
    if (raw == null) return null;
    return Event.fromJson(Map<String, dynamic>.from(raw));
  }

  Future<void> saveEvent(Event event) async {
    await _eventsBox.put(event.id, event.toJson());
  }

  Future<void> saveEvents(List<Event> events) async {
    final entries = <String, Map<String, dynamic>>{
      for (final e in events) e.id: e.toJson(),
    };
    await _eventsBox.putAll(entries);
  }

  Future<void> deleteEvent(String id) async {
    await _eventsBox.delete(id);
  }

  // ===================== SYNC QUEUE =====================

  List<Map<String, dynamic>> getPendingSyncItems() {
    return _syncQueueBox.values
        .map((e) => Map<String, dynamic>.from(e))
        .toList()
      ..sort((a, b) {
        final aTime = a['timestamp'] as int? ?? 0;
        final bTime = b['timestamp'] as int? ?? 0;
        return aTime.compareTo(bTime);
      });
  }

  Future<void> addSyncItem(Map<String, dynamic> item) async {
    final id = item['id'] as String;
    await _syncQueueBox.put(id, item);
  }

  Future<void> removeSyncItem(String id) async {
    await _syncQueueBox.delete(id);
  }

  Future<void> clearAllData() async {
    await Future.wait([
      _tasksBox.clear(),
      _notesBox.clear(),
      _eventsBox.clear(),
      _syncQueueBox.clear(),
      _userBox.clear(),
    ]);
  }
}
