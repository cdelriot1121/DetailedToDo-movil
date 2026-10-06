import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/network/dio_client.dart';
import '../models/subtask.dart';
import '../models/task.dart';

final taskApiServiceProvider = Provider<TaskApiService>((ref) {
  final dio = ref.watch(dioClientProvider);
  return TaskApiService(dio);
});

class TaskApiService {
  final Dio _dio;

  TaskApiService(this._dio);

  Future<List<Task>> getTasks({
    String? status,
    String? priority,
    String? folder,
    String? tag,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (status != null && status.isNotEmpty) queryParams['status'] = status;
      if (priority != null && priority.isNotEmpty) {
        queryParams['priority'] = priority;
      }
      if (folder != null && folder.isNotEmpty) queryParams['folder'] = folder;
      if (tag != null && tag.isNotEmpty) queryParams['tag'] = tag;

      final response = await _dio.get(
        '/tasks',
        queryParameters: queryParams.isEmpty ? null : queryParams,
      );

      final data = response.data;
      if (data is List) {
        return data
            .map((item) => Task.fromJson(item as Map<String, dynamic>))
            .toList();
      }
      return [];
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<Task> getTask(String id) async {
    try {
      final response = await _dio.get('/tasks/$id');
      return Task.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<Task> createTask(Map<String, dynamic> taskData) async {
    try {
      final response = await _dio.post('/tasks', data: taskData);
      return Task.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<Task> updateTask(String id, Map<String, dynamic> taskData) async {
    try {
      final response = await _dio.put('/tasks/$id', data: taskData);
      return Task.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<Task> updateStatus(String id, String status) async {
    try {
      final response = await _dio.patch(
        '/tasks/$id/status',
        data: {'status': status},
      );
      return Task.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<void> deleteTask(String id) async {
    try {
      await _dio.delete('/tasks/$id');
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<Task> createTaskWithAI(String content) async {
    try {
      final response = await _dio.post(
        '/tasks/ai',
        data: {'content': content},
      );
      return Task.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<Subtask> createSubtask(String taskId, String title, String description) async {
    try {
      final response = await _dio.post(
        '/tasks/$taskId/subtasks',
        data: {'title': title, 'description': description},
      );
      final task = Task.fromJson(response.data as Map<String, dynamic>);
      return task.subtasks.last;
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<Subtask> updateSubtask(
    String taskId,
    String subtaskId,
    Map<String, dynamic> subtaskData,
  ) async {
    try {
      final response = await _dio.patch(
        '/tasks/$taskId/subtasks/$subtaskId',
        data: subtaskData,
      );
      final task = Task.fromJson(response.data as Map<String, dynamic>);
      return task.subtasks.firstWhere((subtask) => subtask.id == subtaskId);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<void> deleteSubtask(String taskId, String subtaskId) async {
    try {
      await _dio.delete('/tasks/$taskId/subtasks/$subtaskId');
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<Task> generateSubtasksWithAI(String taskId) async {
    try {
      final response = await _dio.post('/tasks/$taskId/subtasks/ai');
      return Task.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }
}
