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
    this.isLoading = false,
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
    try {
      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      final tasks = await _taskRepository.getTasks();
      final events = await _eventRepository.getEvents();

      final pending = tasks.where((t) => t.status != TaskStatus.completed).toList();
      final todayTasks = pending.where((t) {
        if (t.dueDate == null) return false;
        return t.dueDate!.isAfter(startOfDay) && t.dueDate!.isBefore(endOfDay);
      }).length;

      final upcomingEvs = events.where((e) => e.startDate.isAfter(startOfDay)).toList();
      upcomingEvs.sort((a, b) => a.startDate.compareTo(b.startDate));

      final reminders = tasks.where((t) => t.reminderDate != null && t.reminderDate!.isAfter(now)).length +
          events.where((e) => e.reminderDate != null && e.reminderDate!.isAfter(now)).length;

      state = state.copyWith(
        isLoading: false,
        pendingTasks: pending.take(5).toList(),
        upcomingEvents: upcomingEvs.take(3).toList(),
        pendingTasksCount: todayTasks > 0 ? todayTasks : pending.length,
        upcomingEventsCount: upcomingEvs.length,
        remindersCount: reminders,
      );
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Error al actualizar el resumen.',
      );
    }
  }
}
