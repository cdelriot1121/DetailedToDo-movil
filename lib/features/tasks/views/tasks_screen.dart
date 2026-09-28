import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import '../../../app/theme.dart';
import '../../../core/utils/date_utils.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/loading_view.dart';
import '../models/task.dart';
import '../viewmodels/tasks_view_model.dart';

class TasksScreen extends ConsumerWidget {
  const TasksScreen({super.key});

  void _showFilterModal(BuildContext context, WidgetRef ref) {
    final state = ref.read(tasksViewModelProvider);
    String? tempStatus = state.selectedStatus;
    String? tempPriority = state.selectedPriority;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.primarySurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (modalContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Filtros',
                        style: TextStyle(
                          color: AppColors.primaryText,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          ref.read(tasksViewModelProvider.notifier).clearFilters();
                          Navigator.pop(context);
                        },
                        child: const Text(
                          'Limpiar',
                          style: TextStyle(color: AppColors.secondaryText),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Estado',
                    style: TextStyle(
                      color: AppColors.primaryText,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: [
                      _buildChip(
                        'Todos',
                        tempStatus == null,
                        () => setModalState(() => tempStatus = null),
                      ),
                      _buildChip(
                        'Pendiente',
                        tempStatus == 'PENDING',
                        () => setModalState(() => tempStatus = 'PENDING'),
                      ),
                      _buildChip(
                        'En progreso',
                        tempStatus == 'IN_PROGRESS',
                        () => setModalState(() => tempStatus = 'IN_PROGRESS'),
                      ),
                      _buildChip(
                        'Completada',
                        tempStatus == 'COMPLETED',
                        () => setModalState(() => tempStatus = 'COMPLETED'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Prioridad',
                    style: TextStyle(
                      color: AppColors.primaryText,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: [
                      _buildChip(
                        'Todas',
                        tempPriority == null,
                        () => setModalState(() => tempPriority = null),
                      ),
                      _buildChip(
                        'Baja',
                        tempPriority == 'LOW',
                        () => setModalState(() => tempPriority = 'LOW'),
                      ),
                      _buildChip(
                        'Media',
                        tempPriority == 'MEDIUM',
                        () => setModalState(() => tempPriority = 'MEDIUM'),
                      ),
                      _buildChip(
                        'Alta',
                        tempPriority == 'HIGH',
                        () => setModalState(() => tempPriority = 'HIGH'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  AppButton(
                    label: 'Aplicar filtros',
                    onPressed: () {
                      ref.read(tasksViewModelProvider.notifier).setFilter(
                            status: tempStatus,
                            priority: tempPriority,
                          );
                      Navigator.pop(context);
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildChip(String label, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.white : AppColors.secondarySurface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? AppColors.white : AppColors.border,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? AppColors.pureBlack : AppColors.primaryText,
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(tasksViewModelProvider);

    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: AppBar(
        title: const Text('Tareas'),
        actions: [
          IconButton(
            icon: Badge(
              isLabelVisible: state.hasFilters,
              smallSize: 8,
              backgroundColor: AppColors.white,
              child: const Icon(PhosphorIconsRegular.funnelSimple),
            ),
            onPressed: () => _showFilterModal(context, ref),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Builder(
        builder: (context) {
          if (state.isLoading) {
            return const LoadingView(message: 'Cargando tareas...');
          }

          if (state.viewState == TasksViewState.error) {
            return EmptyState(
              icon: PhosphorIconsRegular.warningCircle,
              title: 'Error al cargar tareas',
              message: state.errorMessage,
              actionLabel: 'Reintentar',
              onAction: () =>
                  ref.read(tasksViewModelProvider.notifier).loadTasks(),
              isError: true,
            );
          }

          if (state.isEmpty) {
            return EmptyState(
              icon: PhosphorIconsRegular.checkCircle,
              title: 'No hay tareas',
              message: state.hasFilters
                  ? 'No hay tareas que coincidan con los filtros seleccionados.'
                  : 'Crea tu primera tarea o utiliza la IA para organizarte.',
              actionLabel: state.hasFilters ? 'Limpiar filtros' : 'Crear tarea',
              onAction: () {
                if (state.hasFilters) {
                  ref.read(tasksViewModelProvider.notifier).clearFilters();
                } else {
                  context.push('/tasks/new');
                }
              },
            );
          }

          return RefreshIndicator(
            color: AppColors.white,
            backgroundColor: AppColors.primarySurface,
            onRefresh: () => ref
                .read(tasksViewModelProvider.notifier)
                .loadTasks(isRefresh: true),
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              itemCount: state.tasks.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final task = state.tasks[index];
                return _TaskCard(
                  task: task,
                  onTap: () async {
                    await context.push('/tasks/${task.id}');
                    ref.read(tasksViewModelProvider.notifier).loadTasks();
                  },
                  onToggle: () {
                    ref.read(tasksViewModelProvider.notifier).toggleTaskStatus(task);
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

class _TaskCard extends StatelessWidget {
  final Task task;
  final VoidCallback onTap;
  final VoidCallback onToggle;

  const _TaskCard({
    required this.task,
    required this.onTap,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final isDone = task.isCompleted;

    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Custom Monochrome Checkbox
          GestureDetector(
            onTap: onToggle,
            child: Container(
              width: 22,
              height: 22,
              margin: const EdgeInsets.only(top: 2, right: 12),
              decoration: BoxDecoration(
                color: isDone ? AppColors.white : Colors.transparent,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isDone ? AppColors.white : AppColors.secondaryText,
                  width: 1.5,
                ),
              ),
              child: isDone
                  ? const Icon(
                      PhosphorIconsBold.check,
                      size: 14,
                      color: AppColors.pureBlack,
                    )
                  : null,
            ),
          ),

          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        task.title,
                        style: TextStyle(
                          color: isDone
                              ? AppColors.disabledText
                              : AppColors.primaryText,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          decoration:
                              isDone ? TextDecoration.lineThrough : null,
                          letterSpacing: -0.2,
                        ),
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
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                  ],
                ),
                if (task.description != null &&
                    task.description!.trim().isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    task.description!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: isDone
                          ? AppColors.disabledText
                          : AppColors.secondaryText,
                      fontSize: 13,
                    ),
                  ),
                ],
                const SizedBox(height: 8),
                Row(
                  children: [
                    if (task.folder != null && task.folder!.isNotEmpty) ...[
                      Icon(
                        PhosphorIconsRegular.folderSimple,
                        size: 14,
                        color: AppColors.secondaryText,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        task.folder!,
                        style: const TextStyle(
                          color: AppColors.secondaryText,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(width: 10),
                    ],
                    if (task.dueDate != null) ...[
                      Icon(
                        PhosphorIconsRegular.calendarBlank,
                        size: 14,
                        color: AppColors.secondaryText,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        AppDateUtils.formatShort(task.dueDate),
                        style: const TextStyle(
                          color: AppColors.secondaryText,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(width: 10),
                    ],
                    if (task.subtasks.isNotEmpty) ...[
                      Icon(
                        PhosphorIconsRegular.listChecks,
                        size: 14,
                        color: AppColors.secondaryText,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${task.completedSubtasksCount}/${task.totalSubtasksCount}',
                        style: const TextStyle(
                          color: AppColors.secondaryText,
                          fontSize: 12,
                        ),
                      ),
                    ],
                    if (task.isAIGenerating) ...[
                      const SizedBox(width: 8),
                      const Icon(
                        PhosphorIconsRegular.sparkle,
                        size: 14,
                        color: AppColors.white,
                      ),
                      const SizedBox(width: 4),
                      const Text(
                        'IA...',
                        style: TextStyle(
                          color: AppColors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
