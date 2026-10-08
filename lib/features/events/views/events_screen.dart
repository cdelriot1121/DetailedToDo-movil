import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import '../../../app/theme.dart';
import '../../../core/utils/date_utils.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/loading_view.dart';
import '../models/event.dart';
import '../viewmodels/events_view_model.dart';

class EventsScreen extends ConsumerWidget {
  const EventsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(eventsViewModelProvider);
    final events = state.events;
    final selectedDate = state.fromDate ?? DateTime.now();

    return Scaffold(
      backgroundColor: context.palette.scaffoldBackground,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Eventos'),
            Text(
              '${_monthName(selectedDate.month)} ${selectedDate.year}',
              style: TextStyle(
                color: context.palette.secondaryText,
                fontSize: 13,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(PhosphorIconsRegular.sparkle, size: 20),
            onPressed: () => context.push('/events/ai'),
            tooltip: 'Agendar con IA',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: context.palette.accent,
        foregroundColor: context.palette.onAccent,
        shape: const CircleBorder(),
        onPressed: () => context.push('/events/new'),
        child: const Icon(PhosphorIconsRegular.plus, size: 24),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          color: context.palette.accent,
          backgroundColor: context.palette.surface,
          onRefresh: () =>
              ref.read(eventsViewModelProvider.notifier).loadEvents(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Horizontal Week Strip
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                child: SizedBox(
                  height: 70,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: 7,
                    separatorBuilder: (_, _) => const SizedBox(width: 8),
                    itemBuilder: (context, index) {
                      final date = DateTime.now().add(
                        Duration(days: index - 2),
                      );
                      final selectedDate = state.fromDate;
                      final isSelected = selectedDate == null
                          ? index == 2
                          : selectedDate.year == date.year &&
                                selectedDate.month == date.month &&
                                selectedDate.day == date.day;

                      return InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () {
                          final start = DateTime(
                            date.year,
                            date.month,
                            date.day,
                          );
                          ref
                              .read(eventsViewModelProvider.notifier)
                              .setDateRange(
                                start,
                                start.add(const Duration(days: 1)),
                              );
                        },
                        child: Container(
                          width: 44,
                          decoration: BoxDecoration(
                            color: isSelected
                                ? context.palette.accent
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isSelected
                                  ? context.palette.accent
                                  : Colors.transparent,
                            ),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                _weekdayLetter(date),
                                style: TextStyle(
                                  color: isSelected
                                      ? context.palette.onAccent
                                      : context.palette.secondaryText,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${date.day}',
                                style: TextStyle(
                                  color: isSelected
                                      ? context.palette.onAccent
                                      : context.palette.primaryText,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),

              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 8,
                ),
                child: Text(
                  selectedDate.year == DateTime.now().year &&
                          selectedDate.month == DateTime.now().month &&
                          selectedDate.day == DateTime.now().day
                      ? 'Agenda de hoy'
                      : 'Agenda · ${AppDateUtils.formatEventBadge(selectedDate)}',
                  style: TextStyle(
                    color: context.palette.primaryText,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),

              Expanded(
                child: state.isLoading && events.isEmpty
                    ? const LoadingView(message: 'Cargando eventos...')
                    : state.errorMessage != null && events.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Text(
                            state.errorMessage!,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: context.palette.secondaryText,
                            ),
                          ),
                        ),
                      )
                    : events.isEmpty
                    ? const EmptyState(
                        icon: PhosphorIconsRegular.calendarBlank,
                        title: 'No hay eventos',
                        message:
                            'Programa un evento o usa la IA para agendar automáticamente.',
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 8,
                        ),
                        itemCount: events.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final event = events[index];
                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(
                                width: 64,
                                child: Padding(
                                  padding: const EdgeInsets.only(
                                    top: 8,
                                    right: 8,
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        DateFormat(
                                          'h:mm',
                                        ).format(event.startDate.toLocal()),
                                        style: TextStyle(
                                          color: context.palette.primaryText,
                                          fontSize: 17,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      Text(
                                        event.startDate.toLocal().hour < 12
                                            ? 'a. m.'
                                            : 'p. m.',
                                        style: TextStyle(
                                          color: context.palette.secondaryText,
                                          fontSize: 11,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              Expanded(child: _buildEventCard(context, event)),
                            ],
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEventCard(BuildContext context, Event event) {
    return AppCard(
      onTap: () => context.push('/events/${event.id}', extra: event),
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 4,
            height: 48,
            decoration: BoxDecoration(
              color: context.palette.accent,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  event.title,
                  style: TextStyle(
                    color: context.palette.primaryText,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (event.location?.isNotEmpty == true) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        PhosphorIconsRegular.mapPin,
                        size: 12,
                        color: context.palette.secondaryText,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          event.location!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: context.palette.secondaryText,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
                if (event.description?.isNotEmpty == true) ...[
                  const SizedBox(height: 4),
                  Text(
                    event.description!,
                    style: TextStyle(
                      color: context.palette.secondaryText,
                      fontSize: 13,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

String _weekdayLetter(DateTime date) {
  const weekdays = ['L', 'M', 'X', 'J', 'V', 'S', 'D'];
  return weekdays[date.weekday - 1];
}

String _monthName(int month) {
  const months = [
    'Enero',
    'Febrero',
    'Marzo',
    'Abril',
    'Mayo',
    'Junio',
    'Julio',
    'Agosto',
    'Septiembre',
    'Octubre',
    'Noviembre',
    'Diciembre',
  ];
  return months[month - 1];
}
