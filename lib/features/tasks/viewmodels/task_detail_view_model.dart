import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/notifications/notification_service.dart';
import '../data/task_repository.dart';
import '../models/task.dart';

class TaskDetailState {
  final Task? task;
  final bool isLoading;
  final bool isSubmitting;
  final bool isPollingAI;
  final String? errorMessage;

  const TaskDetailState({
    this.task,
    this.isLoading = false,
    this.isSubmitting = false,
    this.isPollingAI = false,
    this.errorMessage,
  });

  TaskDetailState copyWith({
    Task? task,
    bool? isLoading,
    bool? isSubmitting,
    bool? isPollingAI,
    String? errorMessage,
    bool clearError = false,
  }) {
    return TaskDetailState(
      task: task ?? this.task,
      isLoading: isLoading ?? this.isLoading,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      isPollingAI: isPollingAI ?? this.isPollingAI,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

final taskDetailViewModelProvider = NotifierProvider.autoDispose
    .family<TaskDetailViewModel, TaskDetailState, String>(TaskDetailViewModel.new);

class TaskDetailViewModel extends Notifier<TaskDetailState> {
  final String taskId;

  TaskDetailViewModel(this.taskId);

  TaskRepository get _repository => ref.read(taskRepositoryProvider);
  NotificationService get _notificationService => ref.read(notificationServiceProvider);

  Timer? _pollingTimer;
  int _pollCount = 0;
  static const int _maxPollAttempts = 15; // ~45s max

  @override
  TaskDetailState build() {
    ref.onDispose(() {
      _stopPolling();
    });

    Future.microtask(() => loadTask());
    return const TaskDetailState();
  }

  void _stopPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
  }

  Future<void> loadTask() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final task = await _repository.getTask(taskId);
      state = state.copyWith(isLoading: false, task: task);

      if (task.subtasksGenerationStatus == 'PENDING') {
        _startPolling();
      }
    } on ApiException catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.message);
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Error al cargar el detalle de la tarea.',
      );
    }
  }

  void _startPolling() {
    _stopPolling();
    _pollCount = 0;
    state = state.copyWith(isPollingAI: true);

    _pollingTimer = Timer.periodic(const Duration(seconds: 3), (timer) async {
      _pollCount++;
      if (_pollCount > _maxPollAttempts) {
        _stopPolling();
        state = state.copyWith(isPollingAI: false);
        return;
      }

      try {
        final updatedTask = await _repository.getTask(taskId);
        final status = updatedTask.subtasksGenerationStatus;

        if (status != 'PENDING') {
          _stopPolling();
          state = state.copyWith(task: updatedTask, isPollingAI: false);
          if (status == 'COMPLETED') {
            await _notificationService.showAICompletedNotification(
              taskTitle: updatedTask.title,
            );
          }
        } else {
          state = state.copyWith(task: updatedTask);
        }
      } catch (_) {
        _stopPolling();
        state = state.copyWith(isPollingAI: false);
      }
    });
  }

  Future<void> toggleStatus() async {
    final current = state.task;
    if (current == null) return;

    final nextStatus = current.status == TaskStatus.completed
        ? TaskStatus.pending
        : TaskStatus.completed;

    state = state.copyWith(task: current.copyWith(status: nextStatus));

    try {
      final updated = await _repository.updateStatus(taskId, nextStatus);
      state = state.copyWith(task: updated);
    } catch (_) {
      state = state.copyWith(task: current);
    }
  }

  Future<bool> addSubtask(String title, String description) async {
    if (title.trim().isEmpty) return false;
    try {
      final newSubtask = await _repository.addSubtask(taskId, title.trim(), description.trim());
      final currentTask = state.task;
      if (currentTask != null) {
        final updatedSubtasks = [...currentTask.subtasks, newSubtask];
        state = state.copyWith(
          task: currentTask.copyWith(subtasks: updatedSubtasks),
        );
      }
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> toggleSubtask(String subtaskId, bool completed) async {
    final currentTask = state.task;
    if (currentTask == null) return;

    final updatedSubtasks = currentTask.subtasks.map((s) {
      if (s.id == subtaskId) {
        return s.copyWith(completed: completed);
      }
      return s;
    }).toList();

    state = state.copyWith(
      task: currentTask.copyWith(subtasks: updatedSubtasks),
    );

    try {
      final subtask = currentTask.subtasks.firstWhere((s) => s.id == subtaskId);
      await _repository.toggleSubtask(taskId, subtaskId, completed, subtask.title, subtask.description);
    } catch (_) {
      state = state.copyWith(task: currentTask);
    }
  }

  Future<bool> deleteSubtask(String subtaskId) async {
    final currentTask = state.task;
    if (currentTask == null) return false;

    try {
      await _repository.deleteSubtask(taskId, subtaskId);
      final updatedSubtasks =
          currentTask.subtasks.where((s) => s.id != subtaskId).toList();
      state = state.copyWith(
        task: currentTask.copyWith(subtasks: updatedSubtasks),
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> requestAISubtasks() async {
    try {
      final updated = await _repository.generateSubtasksWithAI(taskId);
      state = state.copyWith(task: updated);
      if (updated.subtasksGenerationStatus == 'PENDING') {
        _startPolling();
      }
    } catch (e) {
      state = state.copyWith(errorMessage: 'No se pudieron generar subtareas con IA.');
    }
  }
}
