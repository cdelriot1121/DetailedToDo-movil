import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/notifications/notification_service.dart';
import '../../../core/network/api_exception.dart';
import '../data/task_repository.dart';
import '../models/task.dart';

enum TasksViewState {
  initial,
  loading,
  success,
  empty,
  error,
  refreshing,
}

class TasksState {
  final TasksViewState viewState;
  final List<Task> tasks;
  final String? selectedStatus;
  final String? selectedPriority;
  final String? selectedFolder;
  final String? selectedTag;
  final String? errorMessage;

  const TasksState({
    this.viewState = TasksViewState.initial,
    this.tasks = const [],
    this.selectedStatus,
    this.selectedPriority,
    this.selectedFolder,
    this.selectedTag,
    this.errorMessage,
  });

  bool get isLoading => viewState == TasksViewState.loading;
  bool get isRefreshing => viewState == TasksViewState.refreshing;
  bool get isEmpty => viewState == TasksViewState.empty;
  bool get hasFilters =>
      selectedStatus != null ||
      selectedPriority != null ||
      selectedFolder != null ||
      selectedTag != null;

  TasksState copyWith({
    TasksViewState? viewState,
    List<Task>? tasks,
    String? selectedStatus,
    String? selectedPriority,
    String? selectedFolder,
    String? selectedTag,
    String? errorMessage,
    bool clearStatus = false,
    bool clearPriority = false,
    bool clearFolder = false,
    bool clearTag = false,
    bool clearError = false,
  }) {
    return TasksState(
      viewState: viewState ?? this.viewState,
      tasks: tasks ?? this.tasks,
      selectedStatus: clearStatus ? null : (selectedStatus ?? this.selectedStatus),
      selectedPriority:
          clearPriority ? null : (selectedPriority ?? this.selectedPriority),
      selectedFolder: clearFolder ? null : (selectedFolder ?? this.selectedFolder),
      selectedTag: clearTag ? null : (selectedTag ?? this.selectedTag),
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

final tasksViewModelProvider =
    NotifierProvider<TasksViewModel, TasksState>(TasksViewModel.new);

class TasksViewModel extends Notifier<TasksState> {
  TaskRepository get _repository => ref.read(taskRepositoryProvider);

  @override
  TasksState build() {
    // Schedule initial load after build
    Future.microtask(() => loadTasks());
    return const TasksState();
  }

  Future<void> loadTasks({bool isRefresh = false}) async {
    if (isRefresh) {
      state = state.copyWith(viewState: TasksViewState.refreshing, clearError: true);
    } else {
      state = state.copyWith(viewState: TasksViewState.loading, clearError: true);
    }

    try {
      final tasks = await _repository.getTasks(
        status: state.selectedStatus,
        priority: state.selectedPriority,
        folder: state.selectedFolder,
        tag: state.selectedTag,
      );
      for (final task in tasks) {
        ref.read(notificationServiceProvider).scheduleTaskReminders(
          taskId: task.id,
          title: task.title,
          reminderDate: task.isCompleted ? null : task.reminderDate,
          dueDate: task.isCompleted ? null : task.dueDate,
          lastMinuteReminderMinutes: task.isCompleted ? null : task.lastMinuteReminderMinutes,
        );
      }

      if (tasks.isEmpty) {
        state = state.copyWith(
          viewState: TasksViewState.empty,
          tasks: [],
          clearError: true,
        );
      } else {
        state = state.copyWith(
          viewState: TasksViewState.success,
          tasks: tasks,
          clearError: true,
        );
      }
    } on ApiException catch (e) {
      state = state.copyWith(
        viewState: TasksViewState.error,
        errorMessage: e.message,
      );
    } catch (_) {
      state = state.copyWith(
        viewState: TasksViewState.error,
        errorMessage: 'Error al cargar las tareas.',
      );
    }
  }

  void setFilter({
    String? status,
    String? priority,
    String? folder,
    String? tag,
  }) {
    state = state.copyWith(
      selectedStatus: status,
      selectedPriority: priority,
      selectedFolder: folder,
      selectedTag: tag,
    );
    loadTasks();
  }

  void clearFilters() {
    state = state.copyWith(
      clearStatus: true,
      clearPriority: true,
      clearFolder: true,
      clearTag: true,
    );
    loadTasks();
  }

  Future<void> toggleTaskStatus(Task task) async {
    final nextStatus = task.status == TaskStatus.completed
        ? TaskStatus.pending
        : TaskStatus.completed;

    final updatedList = state.tasks.map((t) {
      if (t.id == task.id) {
        return t.copyWith(status: nextStatus);
      }
      return t;
    }).toList();

    state = state.copyWith(tasks: updatedList);

    try {
      final updatedTask = await _repository.updateStatus(task.id, nextStatus);
      ref.read(notificationServiceProvider).scheduleTaskReminders(
        taskId: updatedTask.id,
        title: updatedTask.title,
        reminderDate: updatedTask.isCompleted ? null : updatedTask.reminderDate,
        dueDate: updatedTask.isCompleted ? null : updatedTask.dueDate,
        lastMinuteReminderMinutes: updatedTask.isCompleted ? null : updatedTask.lastMinuteReminderMinutes,
      );
      final syncedList = state.tasks.map((t) {
        if (t.id == task.id) {
          return updatedTask;
        }
        return t;
      }).toList();
      state = state.copyWith(tasks: syncedList);
    } catch (_) {
      final rollbackList = state.tasks.map((t) {
        if (t.id == task.id) {
          return task;
        }
        return t;
      }).toList();
      state = state.copyWith(tasks: rollbackList);
      ref.read(notificationServiceProvider).scheduleTaskReminders(
        taskId: task.id,
        title: task.title,
        reminderDate: task.reminderDate,
        dueDate: task.dueDate,
        lastMinuteReminderMinutes: task.lastMinuteReminderMinutes,
      );
    }
  }

  void updateTaskSnapshot(Task task) {
    state = state.copyWith(
      tasks: state.tasks.map((item) => item.id == task.id ? task : item).toList(),
    );
  }

  Future<bool> deleteTask(String id) async {
    try {
      ref.read(notificationServiceProvider).scheduleTaskReminders(taskId: id, title: '');
      await _repository.deleteTask(id);
      state = state.copyWith(
        tasks: state.tasks.where((t) => t.id != id).toList(),
      );
      if (state.tasks.isEmpty) {
        state = state.copyWith(viewState: TasksViewState.empty);
      }
      return true;
    } catch (e) {
      return false;
    }
  }
}
