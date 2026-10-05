import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import '../../../core/utils/date_utils.dart';
import '../../../core/widgets/loading_view.dart';
import '../../auth/viewmodels/auth_view_model.dart';
import '../../tasks/models/task.dart';
import '../../tasks/viewmodels/tasks_view_model.dart';
import '../viewmodels/home_view_model.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authViewModelProvider);
    final homeState = ref.watch(homeViewModelProvider);
    final userName = authState.user?.name ?? 'Carlos';
    final userInitial = userName.isNotEmpty ? userName[0].toUpperCase() : 'C';

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      body: SafeArea(
        child: RefreshIndicator(
          color: const Color(0xFF111111),
          backgroundColor: Colors.white,
          onRefresh: () => ref.read(homeViewModelProvider.notifier).loadHomeData(),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Top Header: Greeting, Date, Avatar, AI Sparkle Button
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Hola, $userName',
                          style: const TextStyle(
                            color: Color(0xFF111111),
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            letterSpacing: -0.6,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          AppDateUtils.formatFull(DateTime.now()),
                          style: const TextStyle(
                            color: Color(0xFF666666),
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        // AI Sparkle action button matching Penpot
                        GestureDetector(
                          onTap: () => context.push('/tasks/ai'),
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: const Color(0xFF111111),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Center(
                              child: Text(
                                '✦',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        // Avatar
                        GestureDetector(
                          onTap: () => context.push('/profile'),
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: const BoxDecoration(
                              color: Color(0xFF111111),
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                userInitial,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // AI Summary Card (Tarjetas IA from Penpot)
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFF111111),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: const Color(0xFF444444),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'Resumen con IA',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Tienes ${homeState.pendingTasksCount} tareas para hoy. Te sugiero empezar por priorizar tus actividades pendientes.',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // 3 Stat Boxes (Pendientes, Recordatorios, Eventos hoy)
                Row(
                  children: [
                    Expanded(
                      child: _buildStatBox(
                        count: '${homeState.pendingTasksCount}',
                        label: 'Pendientes',
                        numberColor: const Color(0xFF111111),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildStatBox(
                        count: '${homeState.remindersCount}',
                        label: 'Recordatorios',
                        numberColor: const Color(0xFF333333),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildStatBox(
                        count: '${homeState.upcomingEventsCount}',
                        label: 'Eventos hoy',
                        numberColor: const Color(0xFF111111),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 28),

                // Tareas de hoy Section Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Tareas de hoy',
                      style: TextStyle(
                        color: Color(0xFF111111),
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.4,
                      ),
                    ),
                    GestureDetector(
                      onTap: () => context.go('/tasks'),
                      child: const Text(
                        'Ver todas',
                        style: TextStyle(
                          color: Color(0xFF111111),
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                if (homeState.errorMessage != null) ...[
                  Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF4E5),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline, size: 18, color: Color(0xFF8A5200)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            homeState.errorMessage!,
                            style: const TextStyle(color: Color(0xFF6B4300), fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                if (homeState.isLoading) ...[
                  const LoadingView(message: 'Cargando resumen...'),
                ] else if (homeState.pendingTasks.isEmpty) ...[
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE2E2E2)),
                    ),
                    child: const Center(
                      child: Text(
                        'No hay tareas pendientes para hoy',
                        style: TextStyle(color: Color(0xFF666666), fontSize: 14),
                      ),
                    ),
                  ),
                ] else ...[
                  ...homeState.pendingTasks.take(3).map((task) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _buildTaskCard(context, ref, task),
                      )),
                ],
                const SizedBox(height: 24),

                // Próximo evento Section Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Próximo evento',
                      style: TextStyle(
                        color: Color(0xFF111111),
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.4,
                      ),
                    ),
                    GestureDetector(
                      onTap: () => context.go('/events'),
                      child: const Text(
                        'Ver agenda',
                        style: TextStyle(
                          color: Color(0xFF111111),
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                if (homeState.isLoading && homeState.upcomingEvents.isEmpty)
                  const LoadingView(message: 'Cargando eventos...')
                else if (homeState.upcomingEvents.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE2E2E2)),
                    ),
                    child: const Center(
                      child: Text(
                        'No hay próximos eventos',
                        style: TextStyle(color: Color(0xFF666666), fontSize: 14),
                      ),
                    ),
                  )
                else
                  ...homeState.upcomingEvents.take(3).map((event) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFE2E2E2)),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: IntrinsicHeight(
                              child: Row(
                                children: [
                                  Container(width: 6, color: const Color(0xFF444444)),
                                  Expanded(
                                    child: InkWell(
                                      onTap: () => context.push('/events/${event.id}', extra: event),
                                      child: Padding(
                                        padding: const EdgeInsets.all(16),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(event.title, style: const TextStyle(color: Color(0xFF111111), fontSize: 15, fontWeight: FontWeight.w600)),
                                            const SizedBox(height: 4),
                                            Text(
                                              '${AppDateUtils.formatShort(event.startDate)}${event.location?.isNotEmpty == true ? ' · ${event.location}' : ''}',
                                              style: const TextStyle(color: Color(0xFF666666), fontSize: 12),
                                            ),
                                            if (event.description?.isNotEmpty == true) ...[
                                              const SizedBox(height: 4),
                                              Text(event.description!, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Color(0xFF666666), fontSize: 12)),
                                            ],
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      )),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatBox({
    required String count,
    required String label,
    required Color numberColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E2E2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            count,
            style: TextStyle(
              color: numberColor,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF666666),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskCard(BuildContext context, WidgetRef ref, Task task) {
    String priorityText = 'Media';
    Color chipBg = const Color(0xFFEEEEEE);
    Color chipFg = const Color(0xFF555555);

    if (task.priority == TaskPriority.high) {
      priorityText = 'Alta';
      chipBg = const Color(0xFFE9E9E9);
      chipFg = const Color(0xFF222222);
    } else if (task.priority == TaskPriority.low) {
      priorityText = 'Baja';
      chipBg = const Color(0xFFF2F2F2);
      chipFg = const Color(0xFF666666);
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E2E2)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => context.push('/tasks/${task.id}'),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () {
                    ref.read(tasksViewModelProvider.notifier).toggleTaskStatus(task);
                  },
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: task.isCompleted ? const Color(0xFF111111) : const Color(0xFFCCCCCC),
                        width: 2,
                      ),
                      color: task.isCompleted ? const Color(0xFF111111) : Colors.transparent,
                    ),
                    child: task.isCompleted
                        ? const Center(
                            child: Icon(
                              PhosphorIconsBold.check,
                              size: 12,
                              color: Colors.white,
                            ),
                          )
                        : null,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        task.title,
                        style: TextStyle(
                          color: task.isCompleted ? const Color(0xFF666666) : const Color(0xFF111111),
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          decoration: task.isCompleted ? TextDecoration.lineThrough : null,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        task.dueDate != null ? AppDateUtils.formatShort(task.dueDate!) : 'Hoy',
                        style: const TextStyle(
                          color: Color(0xFF666666),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: chipBg,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    priorityText,
                    style: TextStyle(
                      color: chipFg,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
