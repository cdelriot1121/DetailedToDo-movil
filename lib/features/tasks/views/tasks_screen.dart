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

  static Widget _buildChip(String label, bool isSelected, VoidCallback onTap) {
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => onTap(),
      selectedColor: AppColors.white,
      backgroundColor: AppColors.secondarySurface,
      labelStyle: TextStyle(
        color: isSelected ? AppColors.pureBlack : AppColors.primaryText,
        fontSize: 13,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: isSelected ? AppColors.white : AppColors.border,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(tasksViewModelProvider);
    final tasks = state.tasks;

    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: AppBar(
        title: const Text('Tareas'),
        actions: [
          IconButton(
            icon: const Icon(PhosphorIconsRegular.fadersHorizontal, size: 20),
            onPressed: () => _showFilterModal(context, ref),
            tooltip: 'Filtrar',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.white,
        foregroundColor: AppColors.pureBlack,
        shape: const CircleBorder(),
        onPressed: () => context.push('/tasks/new'),
        child: const Icon(PhosphorIconsRegular.plus, size: 24),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.white,
          backgroundColor: AppColors.primarySurface,
          onRefresh: () => ref.read(tasksViewModelProvider.notifier).loadTasks(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Search Bar & AI Quick Action
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppColors.primarySurface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: TextField(
                          onChanged: (value) {
                            // Search filtering if supported
                          },
                          style: const TextStyle(color: AppColors.primaryText, fontSize: 14),
                          decoration: const InputDecoration(
                            hintText: 'Buscar tareas...',
                            prefixIcon: Icon(PhosphorIconsRegular.magnifyingGlass, color: AppColors.secondaryText, size: 18),
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.primarySurface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: IconButton(
                        icon: const Icon(PhosphorIconsRegular.sparkle, color: AppColors.white, size: 20),
                        onPressed: () => context.push('/tasks/ai'),
                        tooltip: 'Crear con IA',
                      ),
                    ),
                  ],
                ),
              ),

              Expanded(
                child: state.isLoading && tasks.isEmpty
                    ? const LoadingView(message: 'Cargando tareas...')
                    : tasks.isEmpty
                        ? const EmptyState(
                            icon: PhosphorIconsRegular.checkCircle,
                            title: 'No hay tareas',
                            message: 'Crea una nueva tarea o ajusta los filtros de búsqueda.',
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                            itemCount: tasks.length,
                            separatorBuilder: (_, _) => const SizedBox(height: 10),
                            itemBuilder: (context, index) {
                              final task = tasks[index];
                              return _buildTaskCard(context, ref, task);
                            },
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTaskCard(BuildContext context, WidgetRef ref, Task task) {
    Color priorityColor = AppColors.lowPriority;
    if (task.priority == TaskPriority.high) priorityColor = AppColors.highPriority;
    if (task.priority == TaskPriority.medium) priorityColor = AppColors.mediumPriority;

    return AppCard(
      onTap: () => context.push('/tasks/${task.id}'),
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () {
              ref.read(tasksViewModelProvider.notifier).toggleTaskStatus(task);
            },
            child: Container(
              width: 22,
              height: 22,
              margin: const EdgeInsets.only(top: 2),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: task.isCompleted ? AppColors.white : AppColors.secondaryText,
                  width: 2,
                ),
                color: task.isCompleted ? AppColors.white : Colors.transparent,
              ),
              child: task.isCompleted
                  ? const Center(
                      child: Icon(
                        PhosphorIconsBold.check,
                        size: 12,
                        color: AppColors.pureBlack,
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
                    color: task.isCompleted ? AppColors.secondaryText : AppColors.primaryText,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    decoration: task.isCompleted ? TextDecoration.lineThrough : null,
                  ),
                ),
                if (task.description?.isNotEmpty == true) ...[
                  const SizedBox(height: 4),
                  Text(
                    task.description!,
                    style: const TextStyle(
                      color: AppColors.secondaryText,
                      fontSize: 13,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: 8),
                Row(
                  children: [
                    if (task.dueDate != null) ...[
                      const Icon(PhosphorIconsRegular.clock, size: 12, color: AppColors.secondaryText),
                      const SizedBox(width: 4),
                      Text(
                        AppDateUtils.formatShort(task.dueDate!),
                        style: const TextStyle(
                          color: AppColors.secondaryText,
                          fontSize: 11,
                        ),
                      ),
                      const SizedBox(width: 12),
                    ],
                    if (task.subtasks.isNotEmpty) ...[
                      const Icon(PhosphorIconsRegular.listChecks, size: 12, color: AppColors.secondaryText),
                      const SizedBox(width: 4),
                      Text(
                        '${task.subtasks.where((s) => s.completed).length}/${task.subtasks.length}',
                        style: const TextStyle(
                          color: AppColors.secondaryText,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            width: 8,
            height: 8,
            margin: const EdgeInsets.only(top: 6),
            decoration: BoxDecoration(
              color: priorityColor,
              shape: BoxShape.circle,
            ),
          ),
        ],
      ),
    );
  }
}
