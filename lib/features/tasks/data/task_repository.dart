import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../core/storage/local_storage_service.dart';
import '../../../core/sync/sync_service.dart';
import '../models/subtask.dart';
import '../models/task.dart';
import 'task_api_service.dart';

final taskRepositoryProvider = Provider<TaskRepository>((ref) {
  final apiService = ref.watch(taskApiServiceProvider);
  final localStorage = ref.watch(localStorageServiceProvider);
  final syncService = ref.watch(syncServiceProvider);
  return TaskRepository(apiService, localStorage, syncService);
});

class TaskRepository {
  final TaskApiService _apiService;
  final LocalStorageService _localStorage;
  final SyncService _syncService;
  final _uuid = const Uuid();

  TaskRepository(
    this._apiService,
    this._localStorage,
    this._syncService,
  );

  Future<List<Task>> getTasks({
    String? status,
    String? priority,
    String? folder,
    String? tag,
  }) async {
    // Try online fetch first and update cache
    try {
      final remoteTasks = await _apiService.getTasks(
        status: status,
        priority: priority,
        folder: folder,
        tag: tag,
      );
      await _localStorage.saveTasks(remoteTasks);
      // Trigger background sync for any offline changes
      _syncService.syncPending().ignore();
      return remoteTasks;
    } catch (_) {
      // Fallback to local cache if offline or server unreachable
      final local = _localStorage.getTasks(
        status: status,
        priority: priority,
        folder: folder,
        tag: tag,
      );
      return local;
    }
  }

  Future<Task> getTask(String id) async {
    try {
      final remoteTask = await _apiService.getTask(id);
      await _localStorage.saveTask(remoteTask);
      return remoteTask;
    } catch (_) {
      final local = _localStorage.getTask(id);
      if (local != null) return local;
      rethrow;
    }
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
    final newId = _uuid.v4();
    final now = DateTime.now();

    final newTask = Task(
      id: newId,
      title: title,
      description: description,
      status: TaskStatus.pending,
      priority: priority,
      dueDate: dueDate,
      reminderDate: reminderDate,
      folder: folder,
      tags: tags,
      subtasks: const [],
      createdAt: now,
      updatedAt: now,
    );

    // Save locally immediately
    await _localStorage.saveTask(newTask);

    final payload = <String, dynamic>{
      'id': newId,
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

    // Register sync item
    await _localStorage.addSyncItem({
      'id': _uuid.v4(),
      'action': 'create_task',
      'resourceId': newId,
      'payload': payload,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });

    // Try sync in background
    _syncService.syncPending().ignore();

    return newTask;
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
    final existing = _localStorage.getTask(id);
    final updatedTask = (existing ?? Task(id: id, title: title)).copyWith(
      title: title,
      description: description,
      status: status,
      priority: priority,
      dueDate: dueDate,
      reminderDate: reminderDate,
      folder: folder,
      tags: tags,
      updatedAt: DateTime.now(),
    );

    // Save locally immediately
    await _localStorage.saveTask(updatedTask);

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

    // Register sync item
    await _localStorage.addSyncItem({
      'id': _uuid.v4(),
      'action': 'update_task',
      'resourceId': id,
      'payload': payload,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });

    _syncService.syncPending().ignore();

    return updatedTask;
  }

  Future<Task> updateStatus(String id, TaskStatus status) async {
    final existing = _localStorage.getTask(id);
    if (existing != null) {
      final updated = existing.copyWith(
        status: status,
        updatedAt: DateTime.now(),
      );
      await _localStorage.saveTask(updated);
    }

    await _localStorage.addSyncItem({
      'id': _uuid.v4(),
      'action': 'update_task_status',
      'resourceId': id,
      'payload': {'status': status.value},
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });

    _syncService.syncPending().ignore();

    final result = _localStorage.getTask(id);
    if (result != null) return result;
    return Task(id: id, title: '', status: status);
  }

  Future<void> deleteTask(String id) async {
    await _localStorage.deleteTask(id);

    await _localStorage.addSyncItem({
      'id': _uuid.v4(),
      'action': 'delete_task',
      'resourceId': id,
      'payload': {},
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });

    _syncService.syncPending().ignore();
  }

  Future<Task> createTaskWithAI(String content) async {
    final created = await _apiService.createTaskWithAI(content);
    await _localStorage.saveTask(created);
    return created;
  }

  Future<Subtask> addSubtask(String taskId, String title, String description) async {
    final subtaskId = _uuid.v4();
    final newSubtask = Subtask(
      id: subtaskId,
      title: title,
      description: description.isNotEmpty ? description : null,
      completed: false,
      createdAt: DateTime.now(),
    );

    final existingTask = _localStorage.getTask(taskId);
    if (existingTask != null) {
      final updatedSubtasks = List<Subtask>.from(existingTask.subtasks)..add(newSubtask);
      final updatedTask = existingTask.copyWith(
        subtasks: updatedSubtasks,
        updatedAt: DateTime.now(),
      );
      await _localStorage.saveTask(updatedTask);
    }

    await _localStorage.addSyncItem({
      'id': _uuid.v4(),
      'action': 'add_subtask',
      'resourceId': taskId,
      'payload': {
        'title': title,
        'description': description,
      },
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });

    _syncService.syncPending().ignore();

    return newSubtask;
  }

  Future<Subtask> toggleSubtask(
    String taskId,
    String subtaskId,
    bool completed,
    String title,
    String? description,
  ) async {
    final existingTask = _localStorage.getTask(taskId);
    Subtask? modifiedSubtask;

    if (existingTask != null) {
      final updatedSubtasks = existingTask.subtasks.map((s) {
        if (s.id == subtaskId) {
          modifiedSubtask = s.copyWith(
            title: title,
            description: description,
            completed: completed,
          );
          return modifiedSubtask!;
        }
        return s;
      }).toList();

      final updatedTask = existingTask.copyWith(
        subtasks: updatedSubtasks,
        updatedAt: DateTime.now(),
      );
      await _localStorage.saveTask(updatedTask);
    }

    await _localStorage.addSyncItem({
      'id': _uuid.v4(),
      'action': 'update_subtask',
      'resourceId': taskId,
      'payload': {
        'subtaskId': subtaskId,
        'data': {
          'title': title,
          'description': description,
          'status': completed ? 'COMPLETED' : 'PENDING',
        },
      },
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });

    _syncService.syncPending().ignore();

    return modifiedSubtask ??
        Subtask(
          id: subtaskId,
          title: title,
          description: description,
          completed: completed,
        );
  }

  Future<void> deleteSubtask(String taskId, String subtaskId) async {
    final existingTask = _localStorage.getTask(taskId);
    if (existingTask != null) {
      final updatedSubtasks =
          existingTask.subtasks.where((s) => s.id != subtaskId).toList();
      final updatedTask = existingTask.copyWith(
        subtasks: updatedSubtasks,
        updatedAt: DateTime.now(),
      );
      await _localStorage.saveTask(updatedTask);
    }

    await _localStorage.addSyncItem({
      'id': _uuid.v4(),
      'action': 'delete_subtask',
      'resourceId': taskId,
      'payload': {
        'subtaskId': subtaskId,
      },
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });

    _syncService.syncPending().ignore();
  }

  Future<Task> generateSubtasksWithAI(String taskId) async {
    final task = await _apiService.generateSubtasksWithAI(taskId);
    await _localStorage.saveTask(task);
    return task;
  }
}
