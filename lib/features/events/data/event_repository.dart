import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../core/storage/local_storage_service.dart';
import '../../../core/sync/sync_service.dart';
import '../models/event.dart';
import 'event_api_service.dart';

final eventRepositoryProvider = Provider<EventRepository>((ref) {
  final apiService = ref.watch(eventApiServiceProvider);
  final localStorage = ref.watch(localStorageServiceProvider);
  final syncService = ref.watch(syncServiceProvider);
  return EventRepository(apiService, localStorage, syncService);
});

class EventRepository {
  final EventApiService _apiService;
  final LocalStorageService _localStorage;
  final SyncService _syncService;
  final _uuid = const Uuid();

  EventRepository(
    this._apiService,
    this._localStorage,
    this._syncService,
  );

  Future<List<Event>> getEvents({
    DateTime? from,
    DateTime? to,
  }) async {
    try {
      final remoteEvents = await _apiService.getEvents(from: from, to: to);
      await _localStorage.saveEvents(remoteEvents);
      _syncService.syncPending().ignore();
      return remoteEvents;
    } catch (_) {
      return _localStorage.getEvents(from: from, to: to);
    }
  }

  Future<Event> getEvent(String id) async {
    try {
      final remoteEvent = await _apiService.getEvent(id);
      await _localStorage.saveEvent(remoteEvent);
      return remoteEvent;
    } catch (_) {
      final local = _localStorage.getEvent(id);
      if (local != null) return local;
      rethrow;
    }
  }

  Future<Event> createEvent({
    required String title,
    String? description,
    required DateTime startDate,
    DateTime? endDate,
    String? location,
    DateTime? reminderDate,
    List<String> tags = const [],
  }) async {
    final newId = _uuid.v4();
    final now = DateTime.now();

    final newEvent = Event(
      id: newId,
      title: title,
      description: description,
      startDate: startDate,
      endDate: endDate,
      location: location,
      reminderDate: reminderDate,
      tags: tags,
      createdAt: now,
      updatedAt: now,
    );

    // Save locally immediately
    await _localStorage.saveEvent(newEvent);

    final isoDate = startDate.toIso8601String();
    final payload = <String, dynamic>{
      'id': newId,
      'title': title,
      'dateTime': isoDate,
      'startDate': isoDate,
      'tags': tags,
    };
    if (description != null && description.isNotEmpty) {
      payload['description'] = description;
    }
    if (endDate != null) {
      payload['endDate'] = endDate.toIso8601String();
    }
    if (location != null && location.isNotEmpty) {
      payload['location'] = location;
    }
    if (reminderDate != null) {
      payload['reminderDate'] = reminderDate.toIso8601String();
    }

    // Register sync item
    await _localStorage.addSyncItem({
      'id': _uuid.v4(),
      'action': 'create_event',
      'resourceId': newId,
      'payload': payload,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });

    _syncService.syncPending().ignore();

    return newEvent;
  }

  Future<Event> updateEvent(
    String id, {
    required String title,
    String? description,
    required DateTime startDate,
    DateTime? endDate,
    String? location,
    DateTime? reminderDate,
    List<String> tags = const [],
  }) async {
    final existing = _localStorage.getEvent(id);
    final updatedEvent = (existing ??
            Event(
              id: id,
              title: title,
              startDate: startDate,
            ))
        .copyWith(
      title: title,
      description: description,
      startDate: startDate,
      endDate: endDate,
      location: location,
      reminderDate: reminderDate,
      tags: tags,
      updatedAt: DateTime.now(),
    );

    // Save locally immediately
    await _localStorage.saveEvent(updatedEvent);

    final isoDate = startDate.toIso8601String();
    final payload = <String, dynamic>{
      'title': title,
      'dateTime': isoDate,
      'startDate': isoDate,
      'tags': tags,
    };
    if (description != null) payload['description'] = description;
    if (endDate != null) {
      payload['endDate'] = endDate.toIso8601String();
    }
    if (location != null) payload['location'] = location;
    if (reminderDate != null) {
      payload['reminderDate'] = reminderDate.toIso8601String();
    }

    // Register sync item
    await _localStorage.addSyncItem({
      'id': _uuid.v4(),
      'action': 'update_event',
      'resourceId': id,
      'payload': payload,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });

    _syncService.syncPending().ignore();

    return updatedEvent;
  }

  Future<void> deleteEvent(String id) async {
    await _localStorage.deleteEvent(id);

    await _localStorage.addSyncItem({
      'id': _uuid.v4(),
      'action': 'delete_event',
      'resourceId': id,
      'payload': {},
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });

    _syncService.syncPending().ignore();
  }

  Future<Event> createEventWithAI(String content) async {
    final event = await _apiService.createEventWithAI(content);
    await _localStorage.saveEvent(event);
    return event;
  }
}
