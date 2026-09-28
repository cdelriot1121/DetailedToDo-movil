import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/network/dio_client.dart';
import '../models/event.dart';

final eventApiServiceProvider = Provider<EventApiService>((ref) {
  final dio = ref.watch(dioClientProvider);
  return EventApiService(dio);
});

class EventApiService {
  final Dio _dio;

  EventApiService(this._dio);

  Future<List<Event>> getEvents({
    DateTime? from,
    DateTime? to,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (from != null) queryParams['from'] = from.toUtc().toIso8601String();
      if (to != null) queryParams['to'] = to.toUtc().toIso8601String();

      final response = await _dio.get(
        '/events',
        queryParameters: queryParams.isEmpty ? null : queryParams,
      );

      final data = response.data;
      if (data is List) {
        return data
            .map((item) => Event.fromJson(item as Map<String, dynamic>))
            .toList();
      }
      return [];
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<Event> getEvent(String id) async {
    try {
      final response = await _dio.get('/events/$id');
      return Event.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<Event> createEvent(Map<String, dynamic> eventData) async {
    try {
      final response = await _dio.post('/events', data: eventData);
      return Event.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<Event> updateEvent(String id, Map<String, dynamic> eventData) async {
    try {
      final response = await _dio.put('/events/$id', data: eventData);
      return Event.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<void> deleteEvent(String id) async {
    try {
      await _dio.delete('/events/$id');
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<Event> createEventWithAI(String content) async {
    try {
      final response = await _dio.post(
        '/events/ai',
        data: {'content': content},
      );
      return Event.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }
}
