import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/event.dart';
import 'event_api_service.dart';

final eventRepositoryProvider = Provider<EventRepository>((ref) {
  final apiService = ref.watch(eventApiServiceProvider);
  return EventRepository(apiService);
});

class EventRepository {
  final EventApiService _apiService;

  EventRepository(this._apiService);

  Future<List<Event>> getEvents({
    DateTime? from,
    DateTime? to,
  }) async {
    return await _apiService.getEvents(from: from, to: to);
  }

  Future<Event> getEvent(String id) async {
    return await _apiService.getEvent(id);
  }

  Future<Event> createEvent({
    required String title,
    String? description,
    required DateTime startDate,
    DateTime? endDate,
    String? location,
    DateTime? reminderDate,
  }) async {
    final payload = <String, dynamic>{
      'title': title,
      'startDate': startDate.toUtc().toIso8601String(),
    };
    if (description != null && description.isNotEmpty) {
      payload['description'] = description;
    }
    if (endDate != null) {
      payload['endDate'] = endDate.toUtc().toIso8601String();
    }
    if (location != null && location.isNotEmpty) {
      payload['location'] = location;
    }
    if (reminderDate != null) {
      payload['reminderDate'] = reminderDate.toUtc().toIso8601String();
    }

    return await _apiService.createEvent(payload);
  }

  Future<Event> updateEvent(
    String id, {
    required String title,
    String? description,
    required DateTime startDate,
    DateTime? endDate,
    String? location,
    DateTime? reminderDate,
  }) async {
    final payload = <String, dynamic>{
      'title': title,
      'startDate': startDate.toUtc().toIso8601String(),
    };
    if (description != null) payload['description'] = description;
    if (endDate != null) {
      payload['endDate'] = endDate.toUtc().toIso8601String();
    }
    if (location != null) payload['location'] = location;
    if (reminderDate != null) {
      payload['reminderDate'] = reminderDate.toUtc().toIso8601String();
    }

    return await _apiService.updateEvent(id, payload);
  }

  Future<void> deleteEvent(String id) async {
    await _apiService.deleteEvent(id);
  }

  Future<Event> createEventWithAI(String content) async {
    return await _apiService.createEventWithAI(content);
  }
}
