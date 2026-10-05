import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../events/data/event_repository.dart';
import '../../events/models/event.dart';
import '../../tasks/data/task_repository.dart';
import '../../tasks/models/task.dart';

class HomeState {
  final bool isLoading;
  final List<Task> pendingTasks;
  final List<Event> upcomingEvents;
  final int pendingTasksCount;
  final int upcomingEventsCount;
  final int remindersCount;
  final String? errorMessage;

  const HomeState({
    this.isLoading = true,
    this.pendingTasks = const [],
    this.upcomingEvents = const [],
    this.pendingTasksCount = 0,
    this.upcomingEventsCount = 0,
    this.remindersCount = 0,
    this.errorMessage,
  });

  HomeState copyWith({
    bool? isLoading,
    List<Task>? pendingTasks,
    List<Event>? upcomingEvents,
    int? pendingTasksCount,
    int? upcomingEventsCount,
    int? remindersCount,
    String? errorMessage,
    bool clearError = false,
  }) {
    return HomeState(
      isLoading: isLoading ?? this.isLoading,
      pendingTasks: pendingTasks ?? this.pendingTasks,
      upcomingEvents: upcomingEvents ?? this.upcomingEvents,
      pendingTasksCount: pendingTasksCount ?? this.pendingTasksCount,
      upcomingEventsCount: upcomingEventsCount ?? this.upcomingEventsCount,
      remindersCount: remindersCount ?? this.remindersCount,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

final homeViewModelProvider =
    NotifierProvider<HomeViewModel, HomeState>(HomeViewModel.new);

class HomeViewModel extends Notifier<HomeState> {
  TaskRepository get _taskRepository => ref.read(taskRepositoryProvider);
  EventRepository get _eventRepository => ref.read(eventRepositoryProvider);

  @override
  HomeState build() {
    Future.microtask(() => loadHomeData());
    return const HomeState();
  }

  Future<void> loadHomeData() async {
    state = state.copyWith(isLoading: true, clearError: true);
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));
    String? errorMessage;
    List<Task>? tasks;
    List<Event>? events;

    // Keep each section usable when one endpoint is temporarily unavailable.
    try {
      tasks = await _taskRepository.getTasks();
    } catch (_) {
      errorMessage = 'No se pudieron actualizar las tareas.';
    }
    try {
      events = await _eventRepository.getEvents();
    } catch (_) {
      errorMessage = errorMessage == null
          ? 'No se pudieron actualizar los eventos.'
          : 'No se pudieron actualizar tareas ni eventos.';
    }

    final pending = tasks
            ?.where((task) => task.status != TaskStatus.completed)
            .toList() ??
        state.pendingTasks;
    final todayEvents = events
            ?.where((event) =>
                !event.startDate.isBefore(startOfDay) &&
                event.startDate.isBefore(endOfDay))
            .length ??
        state.upcomingEventsCount;
    final upcomingEvents = events
            ?.where((event) => event.startDate.isAfter(now))
            .toList() ??
        state.upcomingEvents;
    upcomingEvents.sort((a, b) => a.startDate.compareTo(b.startDate));

    final todayTasks = pending.where((task) {
      if (task.dueDate == null) return false;
      return !task.dueDate!.isBefore(startOfDay) &&
          task.dueDate!.isBefore(endOfDay);
    }).length;
    final reminders = tasks == null
        ? state.remindersCount
        : tasks.where((task) =>
                task.reminderDate != null && task.reminderDate!.isAfter(now)).length +
            (events ?? const <Event>[]).where((event) =>
                event.reminderDate != null && event.reminderDate!.isAfter(now)).length;

    state = state.copyWith(
      isLoading: false,
      pendingTasks: pending.take(5).toList(),
      upcomingEvents: upcomingEvents.take(3).toList(),
      pendingTasksCount: todayTasks > 0 ? todayTasks : pending.length,
      upcomingEventsCount: todayEvents,
      remindersCount: reminders,
      errorMessage: errorMessage,
    );
  }
}
