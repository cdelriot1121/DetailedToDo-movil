import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/events/data/event_api_service.dart';
import '../../features/notes/data/note_api_service.dart';
import '../../features/tasks/data/task_api_service.dart';
import '../network/api_exception.dart';
import '../storage/local_storage_service.dart';

final syncServiceProvider = Provider<SyncService>((ref) {
  final storage = ref.watch(localStorageServiceProvider);
  final taskApi = ref.watch(taskApiServiceProvider);
  final noteApi = ref.watch(noteApiServiceProvider);
  final eventApi = ref.watch(eventApiServiceProvider);

  return SyncService(storage, taskApi, noteApi, eventApi);
});

class SyncService {
  final LocalStorageService _storage;
  final TaskApiService _taskApi;
  final NoteApiService _noteApi;
  final EventApiService _eventApi;

  bool _isSyncing = false;

  SyncService(
    this._storage,
    this._taskApi,
    this._noteApi,
    this._eventApi,
  );

  bool get isSyncing => _isSyncing;

  Future<void> syncPending() async {
    if (_isSyncing) return;
    _isSyncing = true;

    try {
      final items = _storage.getPendingSyncItems();
      if (items.isEmpty) return;

      for (final item in items) {
        final syncId = item['id'] as String;
        final action = item['action'] as String;
        final resourceId = item['resourceId'] as String?;
        final payload = item['payload'] is Map ? Map<String, dynamic>.from(item['payload'] as Map) : <String, dynamic>{};

        try {
          await _processSyncAction(action, resourceId, payload);
          await _storage.removeSyncItem(syncId);
        } on ApiException catch (e) {
          // If resource not found on remote (404), remove from sync queue to avoid getting stuck
          if (e.statusCode == 404) {
            await _storage.removeSyncItem(syncId);
            continue;
          }
          // If network / server unavailable, stop syncing for now
          if (e.isNetworkError || (e.statusCode != null && e.statusCode! >= 500)) {
            debugPrint('[SyncService] Network error while syncing: ${e.message}');
            break;
          }
          // For other 4xx errors (e.g. invalid payload), discard item to unblock queue
          await _storage.removeSyncItem(syncId);
        } catch (e) {
          debugPrint('[SyncService] Unexpected error processing sync item: $e');
          break;
        }
      }
    } finally {
      _isSyncing = false;
    }
  }

  Future<void> _processSyncAction(
    String action,
    String? resourceId,
    Map<String, dynamic> payload,
  ) async {
    switch (action) {
      // TASKS
      case 'create_task':
        final created = await _taskApi.createTask(payload);
        // Replace or update local entry with server record
        final localTask = _storage.getTask(payload['id']?.toString() ?? created.id);
        if (localTask != null && payload['id'] != created.id) {
          await _storage.deleteTask(localTask.id);
        }
        await _storage.saveTask(created);
        break;

      case 'update_task':
        if (resourceId != null) {
          final updated = await _taskApi.updateTask(resourceId, payload);
          await _storage.saveTask(updated);
        }
        break;

      case 'update_task_status':
        if (resourceId != null) {
          final statusStr = payload['status'] as String? ?? 'PENDING';
          final updated = await _taskApi.updateStatus(resourceId, statusStr);
          await _storage.saveTask(updated);
        }
        break;

      case 'delete_task':
        if (resourceId != null) {
          await _taskApi.deleteTask(resourceId);
        }
        break;

      // SUBTASKS
      case 'add_subtask':
        if (resourceId != null) {
          final title = payload['title'] as String? ?? '';
          final description = payload['description'] as String? ?? '';
          await _taskApi.createSubtask(resourceId, title, description);
        }
        break;

      case 'update_subtask':
        if (resourceId != null) {
          final subtaskId = payload['subtaskId'] as String;
          final subtaskData = Map<String, dynamic>.from(payload['data'] as Map? ?? {});
          await _taskApi.updateSubtask(resourceId, subtaskId, subtaskData);
        }
        break;

      case 'delete_subtask':
        if (resourceId != null) {
          final subtaskId = payload['subtaskId'] as String;
          await _taskApi.deleteSubtask(resourceId, subtaskId);
        }
        break;

      // NOTES
      case 'create_note':
        final created = await _noteApi.createNote(payload);
        final localNote = _storage.getNote(payload['id']?.toString() ?? created.id);
        if (localNote != null && payload['id'] != created.id) {
          await _storage.deleteNote(localNote.id);
        }
        await _storage.saveNote(created);
        break;

      case 'update_note':
        if (resourceId != null) {
          final updated = await _noteApi.updateNote(resourceId, payload);
          await _storage.saveNote(updated);
        }
        break;

      case 'delete_note':
        if (resourceId != null) {
          await _noteApi.deleteNote(resourceId);
        }
        break;

      // EVENTS
      case 'create_event':
        final created = await _eventApi.createEvent(payload);
        final localEvent = _storage.getEvent(payload['id']?.toString() ?? created.id);
        if (localEvent != null && payload['id'] != created.id) {
          await _storage.deleteEvent(localEvent.id);
        }
        await _storage.saveEvent(created);
        break;

      case 'update_event':
        if (resourceId != null) {
          final updated = await _eventApi.updateEvent(resourceId, payload);
          await _storage.saveEvent(updated);
        }
        break;

      case 'delete_event':
        if (resourceId != null) {
          await _eventApi.deleteEvent(resourceId);
        }
        break;
    }
  }
}
