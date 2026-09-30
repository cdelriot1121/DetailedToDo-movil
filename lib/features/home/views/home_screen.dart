import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import '../../../app/theme.dart';
import '../../../core/utils/date_utils.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/loading_view.dart';
import '../../auth/viewmodels/auth_view_model.dart';
import '../../tasks/models/task.dart';
import '../../tasks/viewmodels/tasks_view_model.dart';
import '../viewmodels/home_view_model.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Buenos días';
    if (hour < 19) return 'Buenas tardes';
    return 'Buenas noches';
  }

  void _showQuickCreateSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.primarySurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Nueva creación',
                style: TextStyle(
                  color: AppColors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildCreateOption(
                      ctx,
                      icon: PhosphorIconsRegular.checkCircle,
                      label: 'Tarea',
                      onTap: () {
                        Navigator.pop(ctx);
                        context.push('/tasks/new');
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildCreateOption(
                      ctx,
                      icon: PhosphorIconsRegular.note,
                      label: 'Nota',
                      onTap: () {
                        Navigator.pop(ctx);
                        context.push('/notes/new');
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildCreateOption(
                      ctx,
                      icon: PhosphorIconsRegular.calendarBlank,
                      label: 'Evento',
                      onTap: () {
                        Navigator.pop(ctx);
                        context.push('/events/new');
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              AppButton(
                label: 'Crear con IA',
                variant: AppButtonVariant.ai,
                onPressed: () {
                  Navigator.pop(ctx);
                  _showAIChoiceSheet(context);
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  void _showAIChoiceSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.primarySurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Asistente de IA',
                style: TextStyle(
                  color: AppColors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(PhosphorIconsRegular.checkCircle, color: AppColors.white),
                title: const Text('Generar Tarea con IA', style: TextStyle(color: AppColors.white)),
                subtitle: const Text('Detecta subtareas, fechas y prioridad', style: TextStyle(color: AppColors.secondaryText, fontSize: 12)),
                trailing: const Icon(PhosphorIconsRegular.caretRight, color: AppColors.secondaryText, size: 16),
                onTap: () {
                  Navigator.pop(ctx);
                  context.push('/tasks/ai');
                },
              ),
              const Divider(),
              ListTile(
                leading: const Icon(PhosphorIconsRegular.note, color: AppColors.white),
                title: const Text('Estructurar Nota con IA', style: TextStyle(color: AppColors.white)),
                subtitle: const Text('Organiza notas a partir de ideas libres', style: TextStyle(color: AppColors.secondaryText, fontSize: 12)),
                trailing: const Icon(PhosphorIconsRegular.caretRight, color: AppColors.secondaryText, size: 16),
                onTap: () {
                  Navigator.pop(ctx);
                  context.push('/notes/ai');
                },
              ),
              const Divider(),
              ListTile(
                leading: const Icon(PhosphorIconsRegular.calendarBlank, color: AppColors.white),
                title: const Text('Agendar Evento con IA', style: TextStyle(color: AppColors.white)),
                subtitle: const Text('Extrae fecha, hora y ubicación en lenguaje natural', style: TextStyle(color: AppColors.secondaryText, fontSize: 12)),
                trailing: const Icon(PhosphorIconsRegular.caretRight, color: AppColors.secondaryText, size: 16),
                onTap: () {
                  Navigator.pop(ctx);
                  context.push('/events/ai');
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCreateOption(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 22, color: AppColors.white),
          const SizedBox(height: 6),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.white,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authViewModelProvider);
    final homeState = ref.watch(homeViewModelProvider);
    final userName = authState.user?.name ?? 'Usuario';

    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.white,
        foregroundColor: AppColors.pureBlack,
        shape: const CircleBorder(),
        elevation: 4,
        onPressed: () => _showQuickCreateSheet(context),
        child: const Icon(PhosphorIconsRegular.plus, size: 24),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.white,
          backgroundColor: AppColors.primarySurface,
          onRefresh: () => ref.read(homeViewModelProvider.notifier).loadHomeData(),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header: Greeting & Profile Avatar
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${_getGreeting()},',
                          style: const TextStyle(
                            color: AppColors.secondaryText,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          userName.split(' ').first,
                          style: const TextStyle(
                            color: AppColors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ],
                    ),
                    GestureDetector(
                      onTap: () => context.push('/profile'),
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: AppColors.primarySurface,
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Center(
                          child: Text(
                            (userName.isNotEmpty)
                                ? userName[0].toUpperCase()
                                : 'U',
                            style: const TextStyle(
                              color: AppColors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // "Hoy" Section
                const Text(
                  'Hoy',
                  style: TextStyle(
                    color: AppColors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 10),
                AppCard(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildSummaryMetric(
                        count: homeState.pendingTasksCount,
                        label: 'Pendientes',
                        icon: PhosphorIconsRegular.checkCircle,
                      ),
                      Container(width: 1, height: 36, color: AppColors.border),
                      _buildSummaryMetric(
                        count: homeState.upcomingEventsCount,
                        label: 'Eventos',
                        icon: PhosphorIconsRegular.calendarBlank,
                      ),
                      Container(width: 1, height: 36, color: AppColors.border),
                      _buildSummaryMetric(
                        count: homeState.remindersCount,
                        label: 'Recordatorios',
                        icon: PhosphorIconsRegular.bell,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),

                // "Próximas tareas" Section
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Próximas tareas',
                      style: TextStyle(
                        color: AppColors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    TextButton(
                      onPressed: () => context.go('/tasks'),
                      child: const Text(
                        'Ver todas',
                        style: TextStyle(
                          color: AppColors.secondaryText,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                if (homeState.isLoading) ...[
                  const LoadingView(message: 'Actualizando resumen...'),
                ] else if (homeState.pendingTasks.isEmpty) ...[
                  AppCard(
                    padding: const EdgeInsets.all(20),
                    child: Center(
                      child: Column(
                        children: [
                          const Icon(
                            PhosphorIconsRegular.checkCircle,
                            size: 28,
                            color: AppColors.secondaryText,
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            '¡Estás al día con tus tareas!',
                            style: TextStyle(
                              color: AppColors.primaryText,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'No tienes tareas pendientes urgentes.',
                            style: TextStyle(
                              color: AppColors.secondaryText,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ] else ...[
                  ...homeState.pendingTasks.map((task) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: AppCard(
                        onTap: () async {
                          await context.push('/tasks/${task.id}');
                          ref.read(homeViewModelProvider.notifier).loadHomeData();
                        },
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            GestureDetector(
                              onTap: () async {
                                await ref
                                    .read(tasksViewModelProvider.notifier)
                                    .toggleTaskStatus(task);
                                ref
                                    .read(homeViewModelProvider.notifier)
                                    .loadHomeData();
                              },
                              child: Container(
                                width: 20,
                                height: 20,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: AppColors.secondaryText,
                                    width: 1.5,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    task.title,
                                    style: const TextStyle(
                                      color: AppColors.primaryText,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  if (task.dueDate != null) ...[
                                    const SizedBox(height: 2),
                                    Text(
                                      AppDateUtils.formatShort(task.dueDate),
                                      style: const TextStyle(
                                        color: AppColors.secondaryText,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            if (task.priority == TaskPriority.high)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.secondarySurface,
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(color: AppColors.border),
                                ),
                                child: const Text(
                                  'HIGH',
                                  style: TextStyle(
                                    color: AppColors.white,
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  }),
                ],
                const SizedBox(height: 24),

                // "Próximos eventos" Section
                if (homeState.upcomingEvents.isNotEmpty) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Próximos eventos',
                        style: TextStyle(
                          color: AppColors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      TextButton(
                        onPressed: () => context.go('/events'),
                        child: const Text(
                          'Ver agenda',
                          style: TextStyle(
                            color: AppColors.secondaryText,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ...homeState.upcomingEvents.map((event) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: AppCard(
                        onTap: () => context.push('/events/${event.id}', extra: event),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        child: Row(
                          children: [
                            const Icon(
                              PhosphorIconsRegular.calendarBlank,
                              size: 18,
                              color: AppColors.white,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    event.title,
                                    style: const TextStyle(
                                      color: AppColors.primaryText,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  Text(
                                    AppDateUtils.formatShort(event.startDate),
                                    style: const TextStyle(
                                      color: AppColors.secondaryText,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                ],

                const SizedBox(height: 48),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryMetric({
    required int count,
    required String label,
    required IconData icon,
  }) {
    return Column(
      children: [
        Icon(icon, size: 18, color: AppColors.secondaryText),
        const SizedBox(height: 4),
        Text(
          '$count',
          style: const TextStyle(
            color: AppColors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            color: AppColors.secondaryText,
            fontSize: 11,
          ),
        ),
      ],
    );
  }
}
