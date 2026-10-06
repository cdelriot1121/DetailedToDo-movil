import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import '../../../app/theme.dart';
import '../../../core/utils/date_utils.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/loading_view.dart';
import '../data/event_repository.dart';
import '../models/event.dart';
import '../viewmodels/events_view_model.dart';

class EventDetailScreen extends ConsumerStatefulWidget {
  final String eventId;
  final Event? initialEvent;

  const EventDetailScreen({
    super.key,
    required this.eventId,
    this.initialEvent,
  });

  @override
  ConsumerState<EventDetailScreen> createState() => _EventDetailScreenState();
}

class _EventDetailScreenState extends ConsumerState<EventDetailScreen> {
  Event? _event;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _event = widget.initialEvent;
    if (_event == null) {
      _loadEvent();
    }
  }

  Future<void> _loadEvent() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final repository = ref.read(eventRepositoryProvider);
      final event = await repository.getEvent(widget.eventId);
      setState(() {
        _event = event;
        _isLoading = false;
      });
    } catch (_) {
      setState(() {
        _errorMessage = 'No se pudo cargar el evento.';
        _isLoading = false;
      });
    }
  }

  void _confirmDelete() {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: AppColors.primarySurface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: const BorderSide(color: AppColors.border),
          ),
          title: const Text(
            '¿Eliminar evento?',
            style: TextStyle(color: AppColors.primaryText),
          ),
          content: const Text(
            'Este evento se eliminará permanentemente.',
            style: TextStyle(color: AppColors.secondaryText),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text(
                'Cancelar',
                style: TextStyle(color: AppColors.secondaryText),
              ),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(ctx);
                final deleted = await ref
                    .read(eventsViewModelProvider.notifier)
                    .deleteEvent(widget.eventId);
                if (deleted && mounted) {
                  context.pop();
                }
              },
              child: const Text(
                'Eliminar',
                style: TextStyle(
                  color: AppColors.error,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: AppColors.scaffoldBackground,
        body: LoadingView(message: 'Cargando evento...'),
      );
    }

    if (_errorMessage != null || _event == null) {
      return Scaffold(
        backgroundColor: AppColors.scaffoldBackground,
        appBar: AppBar(),
        body: EmptyState(
          icon: PhosphorIconsRegular.warningCircle,
          title: 'Error',
          message: _errorMessage,
          actionLabel: 'Reintentar',
          onAction: _loadEvent,
          isError: true,
        ),
      );
    }

    final event = _event!;

    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: AppBar(
        title: const Text('Evento'),
        actions: [
          IconButton(
            icon: const Icon(PhosphorIconsRegular.pencilSimple),
            onPressed: () async {
              await context.push('/events/${event.id}/edit', extra: event);
              _loadEvent();
            },
          ),
          IconButton(
            icon: const Icon(PhosphorIconsRegular.trash),
            onPressed: _confirmDelete,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                event.title,
                style: const TextStyle(
                  color: AppColors.primaryText,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 16),

              // Date Info Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.primarySurface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  children: [
                    _buildRow(
                      icon: PhosphorIconsRegular.calendarBlank,
                      title: 'Inicio',
                      value: AppDateUtils.formatFull(event.startDate),
                    ),
                    if (event.endDate != null) ...[
                      const Divider(height: 20),
                      _buildRow(
                        icon: PhosphorIconsRegular.calendarCheck,
                        title: 'Fin',
                        value: AppDateUtils.formatFull(event.endDate),
                      ),
                    ],
                    if (event.location != null &&
                        event.location!.isNotEmpty) ...[
                      const Divider(height: 20),
                      _buildRow(
                        icon: PhosphorIconsRegular.mapPin,
                        title: 'Ubicación',
                        value: event.location!,
                      ),
                    ],
                    if (event.reminderDate != null) ...[
                      const Divider(height: 20),
                      _buildRow(
                        icon: PhosphorIconsRegular.bell,
                        title: 'Recordatorio',
                        value: AppDateUtils.formatFull(event.reminderDate),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 20),

              if (event.description != null &&
                  event.description!.trim().isNotEmpty) ...[
                const Text(
                  'Descripción',
                  style: TextStyle(
                    color: AppColors.primaryText,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  event.description!,
                  style: const TextStyle(
                    color: AppColors.secondaryText,
                    fontSize: 15,
                    height: 1.5,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRow({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.secondaryText),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                color: AppColors.secondaryText,
                fontSize: 11,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: const TextStyle(
                color: AppColors.primaryText,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
