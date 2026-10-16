import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../events/data/event_repository.dart';
import '../../events/models/event.dart';
import '../../tasks/data/task_repository.dart';
import '../../tasks/models/task.dart';
import '../data/home_api_service.dart';

class HomeState {
  final bool isLoading;
  final bool hasLoadedOnce;
  final List<Task> pendingTasks;
  final List<Event> upcomingEvents;
  final int pendingTasksCount;
  final int upcomingEventsCount;
  final int remindersCount;
  final String aiSummary;
  final bool isSummaryLoading;
  final String? errorMessage;

  const HomeState({
    this.isLoading = true,
    this.hasLoadedOnce = false,
    this.pendingTasks = const [],
    this.upcomingEvents = const [],
    this.pendingTasksCount = 0,
    this.upcomingEventsCount = 0,
    this.remindersCount = 0,
    this.aiSummary = 'Revisando tus tareas para recomendarte por dónde empezar…',
    this.isSummaryLoading = false,
    this.errorMessage,
  });

  HomeState copyWith({
    bool? isLoading,
    bool? hasLoadedOnce,
    List<Task>? pendingTasks,
    List<Event>? upcomingEvents,
    int? pendingTasksCount,
    int? upcomingEventsCount,
    int? remindersCount,
    String? aiSummary,
    bool? isSummaryLoading,
    String? errorMessage,
    bool clearError = false,
  }) {
    return HomeState(
      isLoading: isLoading ?? this.isLoading,
      hasLoadedOnce: hasLoadedOnce ?? this.hasLoadedOnce,
      pendingTasks: pendingTasks ?? this.pendingTasks,
      upcomingEvents: upcomingEvents ?? this.upcomingEvents,
      pendingTasksCount: pendingTasksCount ?? this.pendingTasksCount,
      upcomingEventsCount: upcomingEventsCount ?? this.upcomingEventsCount,
      remindersCount: remindersCount ?? this.remindersCount,
      aiSummary: aiSummary ?? this.aiSummary,
      isSummaryLoading: isSummaryLoading ?? this.isSummaryLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

final homeViewModelProvider = NotifierProvider<HomeViewModel, HomeState>(
  HomeViewModel.new,
);

class HomeViewModel extends Notifier<HomeState> {
  TaskRepository get _taskRepository => ref.read(taskRepositoryProvider);
  EventRepository get _eventRepository => ref.read(eventRepositoryProvider);
  HomeApiService get _homeApiService => ref.read(homeApiServiceProvider);
  int _summaryRequestId = 0;

  @override
  HomeState build() {
    Future.microtask(() => loadHomeData());
    return const HomeState();
  }

  Future<void> loadHomeData() async {
    state = state.copyWith(
      isLoading: !state.hasLoadedOnce,
      clearError: true,
    );
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

    final pending =
        tasks?.where((task) => task.status != TaskStatus.completed).toList() ??
        state.pendingTasks;
    final todayEvents =
        events
            ?.where(
              (event) =>
                  !event.startDate.isBefore(startOfDay) &&
                  event.startDate.isBefore(endOfDay),
            )
            .length ??
        state.upcomingEventsCount;
    final upcomingEvents =
        events?.where((event) => event.startDate.isAfter(now)).toList() ??
        state.upcomingEvents;
    upcomingEvents.sort((a, b) => a.startDate.compareTo(b.startDate));

    final reminders = tasks == null
        ? state.remindersCount
        : tasks
                  .where(
                    (task) =>
                        task.reminderDate != null &&
                        task.reminderDate!.isAfter(now),
                  )
                  .length +
              (events ?? const <Event>[])
                  .where(
                    (event) =>
                        event.reminderDate != null &&
                        event.reminderDate!.isAfter(now),
                  )
                  .length;

    state = state.copyWith(
      isLoading: false,
      pendingTasks: pending.take(5).toList(),
      upcomingEvents: upcomingEvents.take(3).toList(),
      pendingTasksCount: pending.length,
      upcomingEventsCount: todayEvents,
      remindersCount: reminders,
      hasLoadedOnce: true,
      errorMessage: errorMessage,
    );
    unawaited(_loadAISummary(pending));
  }

  Future<bool> toggleTaskStatus(Task task) async {
    final nextStatus = task.status == TaskStatus.completed
        ? TaskStatus.pending
        : TaskStatus.completed;
    final previousState = state;
    final updatedTasks = state.pendingTasks
        .map((item) => item.id == task.id ? item.copyWith(status: nextStatus) : item)
        .toList();
    state = state.copyWith(
      pendingTasks: updatedTasks,
      pendingTasksCount: (state.pendingTasksCount +
              (nextStatus == TaskStatus.completed ? -1 : 1))
          .clamp(0, 1 << 30)
          .toInt(),
    );

    try {
      await _taskRepository.updateStatus(task.id, nextStatus);
      await loadHomeData();
      return true;
    } catch (_) {
      state = previousState.copyWith(
        errorMessage: 'No se pudo actualizar el estado de la tarea.',
      );
      return false;
    }
  }

  Future<void> _loadAISummary(List<Task> pendingTasks) async {
    final requestId = ++_summaryRequestId;
    state = state.copyWith(isSummaryLoading: true);
    try {
      final summary = await _homeApiService.getAISummary();
      if (requestId != _summaryRequestId) return;
      state = state.copyWith(aiSummary: summary, isSummaryLoading: false);
    } catch (_) {
      if (requestId != _summaryRequestId) return;
      state = state.copyWith(
        aiSummary: pendingTasks.isEmpty
            ? 'No tienes tareas pendientes. Agrega una y te ayudaré a elegir por dónde empezar.'
            : 'Empieza por «${pendingTasks.first.title}» y avanza en un paso pequeño; después continúa con tus otras tareas.',
        isSummaryLoading: false,
      );
    }
  }
}
