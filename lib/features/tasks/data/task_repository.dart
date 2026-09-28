import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/subtask.dart';
import '../models/task.dart';
import 'task_api_service.dart';

final taskRepositoryProvider = Provider<TaskRepository>((ref) {
  final apiService = ref.watch(taskApiServiceProvider);
  return TaskRepository(apiService);
});

class TaskRepository {
  final TaskApiService _apiService;

  TaskRepository(this._apiService);

  Future<List<Task>> getTasks({
    String? status,
    String? priority,
    String? folder,
    String? tag,
  }) async {
    return await _apiService.getTasks(
      status: status,
      priority: priority,
      folder: folder,
      tag: tag,
    );
  }

  Future<Task> getTask(String id) async {
    return await _apiService.getTask(id);
  }

  Future<Task> createTask({
    required String title,
    String? description,
    TaskPriority priority = TaskPriority.medium,
    DateTime? dueDate,
    DateTime? reminderDate,
    String? folder,
    List<String> tags = const [],
  }) async {
    final payload = <String, dynamic>{
      'title': title,
      'priority': priority.value,
      'tags': tags,
    };
    if (description != null && description.isNotEmpty) {
      payload['description'] = description;
    }
    if (dueDate != null) {
      payload['dueDate'] = dueDate.toUtc().toIso8601String();
    }
    if (reminderDate != null) {
      payload['reminderDate'] = reminderDate.toUtc().toIso8601String();
    }
    if (folder != null && folder.isNotEmpty) {
      payload['folder'] = folder;
    }

    return await _apiService.createTask(payload);
  }

  Future<Task> updateTask(
    String id, {
    required String title,
    String? description,
    TaskStatus? status,
    TaskPriority? priority,
    DateTime? dueDate,
    DateTime? reminderDate,
    String? folder,
    List<String>? tags,
  }) async {
    final payload = <String, dynamic>{
      'title': title,
    };
    if (description != null) payload['description'] = description;
    if (status != null) payload['status'] = status.value;
    if (priority != null) payload['priority'] = priority.value;
    if (dueDate != null) {
      payload['dueDate'] = dueDate.toUtc().toIso8601String();
    }
    if (reminderDate != null) {
      payload['reminderDate'] = reminderDate.toUtc().toIso8601String();
    }
    if (folder != null) payload['folder'] = folder;
    if (tags != null) payload['tags'] = tags;

    return await _apiService.updateTask(id, payload);
  }

  Future<Task> updateStatus(String id, TaskStatus status) async {
    return await _apiService.updateStatus(id, status.value);
  }

  Future<void> deleteTask(String id) async {
    await _apiService.deleteTask(id);
  }

  Future<Task> createTaskWithAI(String content) async {
    return await _apiService.createTaskWithAI(content);
  }

  Future<Subtask> addSubtask(String taskId, String title) async {
    return await _apiService.createSubtask(taskId, title);
  }

  Future<Subtask> toggleSubtask(
    String taskId,
    String subtaskId,
    bool completed,
  ) async {
    return await _apiService.updateSubtask(
      taskId,
      subtaskId,
      {'completed': completed},
    );
  }

  Future<void> deleteSubtask(String taskId, String subtaskId) async {
    await _apiService.deleteSubtask(taskId, subtaskId);
  }

  Future<Task> generateSubtasksWithAI(String taskId) async {
    return await _apiService.generateSubtasksWithAI(taskId);
  }
}
