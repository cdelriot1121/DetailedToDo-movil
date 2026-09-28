import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
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

    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: AppBar(
        title: const Text('Eventos'),
        actions: [
          IconButton(
            icon: const Icon(PhosphorIconsRegular.plus),
            onPressed: () async {
              await context.push('/events/new');
              ref.read(eventsViewModelProvider.notifier).loadEvents();
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Builder(
        builder: (context) {
          if (state.isLoading) {
            return const LoadingView(message: 'Cargando eventos...');
          }

          if (state.viewState == EventsViewState.error) {
            return EmptyState(
              icon: PhosphorIconsRegular.warningCircle,
              title: 'Error al cargar eventos',
              message: state.errorMessage,
              actionLabel: 'Reintentar',
              onAction: () =>
                  ref.read(eventsViewModelProvider.notifier).loadEvents(),
              isError: true,
            );
          }

          if (state.isEmpty) {
            return EmptyState(
              icon: PhosphorIconsRegular.calendarBlank,
              title: 'No hay eventos',
              message: 'Agenda tus reuniones, entregas y actividades importantes.',
              actionLabel: 'Crear evento',
              onAction: () async {
                await context.push('/events/new');
                ref.read(eventsViewModelProvider.notifier).loadEvents();
              },
            );
          }

          return RefreshIndicator(
            color: AppColors.white,
            backgroundColor: AppColors.primarySurface,
            onRefresh: () => ref
                .read(eventsViewModelProvider.notifier)
                .loadEvents(isRefresh: true),
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              itemCount: state.events.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final event = state.events[index];
                return _EventCard(
                  event: event,
                  onTap: () async {
                    await context.push('/events/${event.id}', extra: event);
                    ref.read(eventsViewModelProvider.notifier).loadEvents();
                  },
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class _EventCard extends StatelessWidget {
  final Event event;
  final VoidCallback onTap;

  const _EventCard({
    required this.event,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Date Badge Block
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.secondarySurface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  AppDateUtils.formatEventBadge(event.startDate),
                  style: const TextStyle(
                    color: AppColors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  AppDateUtils.formatTime(event.startDate),
                  style: const TextStyle(
                    color: AppColors.secondaryText,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),

          // Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  event.title,
                  style: const TextStyle(
                    color: AppColors.primaryText,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.2,
                  ),
                ),
                if (event.description != null &&
                    event.description!.trim().isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    event.description!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.secondaryText,
                      fontSize: 13,
                    ),
                  ),
                ],
                if (event.location != null && event.location!.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(
                        PhosphorIconsRegular.mapPin,
                        size: 14,
                        color: AppColors.secondaryText,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          event.location!,
                          style: const TextStyle(
                            color: AppColors.secondaryText,
                            fontSize: 12,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
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
