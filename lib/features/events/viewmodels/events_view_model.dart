import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_exception.dart';
import '../data/event_repository.dart';
import '../models/event.dart';

enum EventsViewState { initial, loading, success, empty, error, refreshing }

class EventsState {
  final EventsViewState viewState;
  final List<Event> events;
  final DateTime? fromDate;
  final DateTime? toDate;
  final String? errorMessage;

  const EventsState({
    this.viewState = EventsViewState.initial,
    this.events = const [],
    this.fromDate,
    this.toDate,
    this.errorMessage,
  });

  bool get isLoading => viewState == EventsViewState.loading;
  bool get isEmpty => viewState == EventsViewState.empty;

  EventsState copyWith({
    EventsViewState? viewState,
    List<Event>? events,
    DateTime? fromDate,
    DateTime? toDate,
    String? errorMessage,
    bool clearDates = false,
    bool clearError = false,
  }) {
    return EventsState(
      viewState: viewState ?? this.viewState,
      events: events ?? this.events,
      fromDate: clearDates ? null : (fromDate ?? this.fromDate),
      toDate: clearDates ? null : (toDate ?? this.toDate),
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

final eventsViewModelProvider = NotifierProvider<EventsViewModel, EventsState>(
  EventsViewModel.new,
);

class EventsViewModel extends Notifier<EventsState> {
  EventRepository get _repository => ref.read(eventRepositoryProvider);

  @override
  EventsState build() {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day);
    final initialState = EventsState(
      fromDate: start,
      toDate: start.add(const Duration(days: 1)),
    );
    Future.microtask(() => loadEvents());
    return initialState;
  }

  Future<void> loadEvents({bool isRefresh = false}) async {
    if (isRefresh) {
      state = state.copyWith(
        viewState: EventsViewState.refreshing,
        clearError: true,
      );
    } else {
      state = state.copyWith(
        viewState: EventsViewState.loading,
        clearError: true,
      );
    }

    try {
      final events = await _repository.getEvents(
        from: state.fromDate,
        to: state.toDate,
      );

      events.sort((a, b) => a.startDate.compareTo(b.startDate));

      if (events.isEmpty) {
        state = state.copyWith(
          viewState: EventsViewState.empty,
          events: [],
          clearError: true,
        );
      } else {
        state = state.copyWith(
          viewState: EventsViewState.success,
          events: events,
          clearError: true,
        );
      }
    } on ApiException catch (e) {
      state = state.copyWith(
        viewState: EventsViewState.error,
        errorMessage: e.message,
      );
    } catch (_) {
      state = state.copyWith(
        viewState: EventsViewState.error,
        errorMessage: 'Error al cargar los eventos.',
      );
    }
  }

  void setDateRange(DateTime? from, DateTime? to) {
    state = state.copyWith(fromDate: from, toDate: to);
    loadEvents();
  }

  void clearFilter() {
    state = state.copyWith(clearDates: true);
    loadEvents();
  }

  Future<bool> deleteEvent(String id) async {
    try {
      await _repository.deleteEvent(id);
      state = state.copyWith(
        events: state.events.where((e) => e.id != id).toList(),
      );
      if (state.events.isEmpty) {
        state = state.copyWith(viewState: EventsViewState.empty);
      }
      return true;
    } catch (_) {
      return false;
    }
  }
}
