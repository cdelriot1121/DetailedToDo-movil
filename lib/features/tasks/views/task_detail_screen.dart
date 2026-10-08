import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import '../../../app/theme.dart';
import '../../../core/utils/date_utils.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/loading_view.dart';
import '../models/task.dart';
import '../viewmodels/task_detail_view_model.dart';
import '../viewmodels/tasks_view_model.dart';

class TaskDetailScreen extends ConsumerStatefulWidget {
  final String taskId;

  const TaskDetailScreen({super.key, required this.taskId});

  @override
  ConsumerState<TaskDetailScreen> createState() => _TaskDetailScreenState();
}

class _TaskDetailScreenState extends ConsumerState<TaskDetailScreen> {
  final _subtaskTextController = TextEditingController();
  final _subtaskDescriptionController = TextEditingController();

  @override
  void dispose() {
    _subtaskTextController.dispose();
    _subtaskDescriptionController.dispose();
    super.dispose();
  }

  void _showAddSubtaskDialog() {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: context.palette.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: BorderSide(color: context.palette.border),
          ),
          title: Text(
            'Nueva subtarea',
            style: TextStyle(color: context.palette.primaryText, fontSize: 18),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _subtaskTextController,
                autofocus: true,
                style: TextStyle(color: context.palette.primaryText),
                decoration: const InputDecoration(hintText: 'Título'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _subtaskDescriptionController,
                maxLines: 3,
                style: TextStyle(color: context.palette.primaryText),
                decoration: const InputDecoration(hintText: 'Descripción'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(
                'Cancelar',
                style: TextStyle(color: context.palette.secondaryText),
              ),
            ),
            TextButton(
              onPressed: () async {
                final value = _subtaskTextController.text;
                if (value.trim().isNotEmpty) {
                  final description = _subtaskDescriptionController.text;
                  Navigator.pop(ctx);
                  await ref
                      .read(taskDetailViewModelProvider(widget.taskId).notifier)
                      .addSubtask(value.trim(), description);
                  _subtaskTextController.clear();
                  _subtaskDescriptionController.clear();
                }
              },
              child: Text(
                'Agregar',
                style: TextStyle(
                  color: context.palette.accent,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _confirmDeleteTask(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: context.palette.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: BorderSide(color: context.palette.border),
          ),
          title: Text(
            '¿Eliminar tarea?',
            style: TextStyle(color: context.palette.primaryText),
          ),
          content: Text(
            'Esta acción eliminará la tarea y todas sus subtareas permanentemente.',
            style: TextStyle(color: context.palette.secondaryText),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(
                'Cancelar',
                style: TextStyle(color: context.palette.secondaryText),
              ),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(ctx);
                final deleted = await ref
                    .read(tasksViewModelProvider.notifier)
                    .deleteTask(widget.taskId);
                if (deleted && context.mounted) {
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
    final state = ref.watch(taskDetailViewModelProvider(widget.taskId));

    if (state.isLoading && state.task == null) {
      return Scaffold(
        backgroundColor: context.palette.scaffoldBackground,
        body: LoadingView(message: 'Cargando detalles de la tarea...'),
      );
    }

    final task = state.task;
    if (task == null) {
      return Scaffold(
        backgroundColor: context.palette.scaffoldBackground,
        appBar: AppBar(title: const Text('Detalle')),
        body: const EmptyState(
          icon: PhosphorIconsRegular.warningCircle,
          title: 'Tarea no encontrada',
          message: 'Es posible que haya sido eliminada.',
        ),
      );
    }

    Color priorityColor = AppColors.lowPriority;
    String priorityLabel = 'Baja';
    if (task.priority == TaskPriority.high) {
      priorityColor = AppColors.highPriority;
      priorityLabel = 'Alta';
    } else if (task.priority == TaskPriority.medium) {
      priorityColor = AppColors.mediumPriority;
      priorityLabel = 'Media';
    }

    return Scaffold(
      backgroundColor: context.palette.scaffoldBackground,
      appBar: AppBar(
        title: const Text('Detalle de Tarea'),
        actions: [
          IconButton(
            icon: const Icon(PhosphorIconsRegular.pencilSimple, size: 20),
            onPressed: () =>
                context.push('/tasks/${task.id}/edit', extra: task),
            tooltip: 'Editar',
          ),
          IconButton(
            icon: const Icon(
              PhosphorIconsRegular.trash,
              size: 20,
              color: AppColors.error,
            ),
            onPressed: () => _confirmDeleteTask(context),
            tooltip: 'Eliminar',
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Main Task Card
              AppCard(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: priorityColor.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: priorityColor.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Text(
                            'Prioridad $priorityLabel',
                            style: TextStyle(
                              color: priorityColor,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        Row(
                          children: [
                            Icon(
                              PhosphorIconsRegular.circle,
                              size: 14,
                              color: context.palette.secondaryText,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              task.status.label,
                              style: TextStyle(
                                color: context.palette.secondaryText,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Text(
                      task.title,
                      style: TextStyle(
                        color: context.palette.primaryText,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.4,
                      ),
                    ),
                    if (task.description?.isNotEmpty == true) ...[
                      const SizedBox(height: 8),
                      Text(
                        task.description!,
                        style: TextStyle(
                          color: context.palette.secondaryText,
                          fontSize: 14,
                          height: 1.4,
                        ),
                      ),
                    ],
                    if (task.folder != null && task.folder!.isNotEmpty || task.tags.isNotEmpty) ...[
                      const SizedBox(height: 14),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          if (task.folder != null && task.folder!.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: context.palette.surfaceSecondary,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: context.palette.border),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    PhosphorIconsRegular.folderSimple,
                                    size: 14,
                                    color: context.palette.secondaryText,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    task.folder!,
                                    style: TextStyle(
                                      color: context.palette.primaryText,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ...task.tags.map(
                            (tag) => Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 9,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: context.palette.surfaceSecondary,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: context.palette.border),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    PhosphorIconsRegular.tag,
                                    size: 12,
                                    color: context.palette.secondaryText,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    tag.startsWith('#') ? tag : '#$tag',
                                    style: TextStyle(
                                      color: context.palette.secondaryText,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                    if (task.dueDate != null || task.reminderDate != null) ...[
                      const SizedBox(height: 16),
                      Divider(color: context.palette.border),
                      const SizedBox(height: 10),
                      if (task.dueDate != null)
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              PhosphorIconsRegular.calendarBlank,
                              size: 16,
                              color: context.palette.secondaryText,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Fecha límite: ${AppDateUtils.formatFull(task.dueDate!)}',
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: context.palette.primaryText,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      if (task.reminderDate != null) ...[
                        if (task.dueDate != null) const SizedBox(height: 8),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              PhosphorIconsRegular.bell,
                              size: 16,
                              color: context.palette.secondaryText,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Recordatorio: ${AppDateUtils.formatFull(task.reminderDate!)}',
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: context.palette.primaryText,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Subtasks Progress Section (Barra de proceso)
              if (task.subtasks.isNotEmpty) ...[
                AppCard(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(
                                PhosphorIconsRegular.chartBar,
                                size: 18,
                                color: context.palette.accent,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Progreso de subtareas',
                                style: TextStyle(
                                  color: context.palette.primaryText,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: task.completedSubtasksCount == task.totalSubtasksCount
                                  ? AppColors.success.withValues(alpha: 0.15)
                                  : context.palette.surfaceSecondary,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '${(task.subtasksProgress * 100).toInt()}%',
                              style: TextStyle(
                                color: task.completedSubtasksCount == task.totalSubtasksCount
                                    ? AppColors.success
                                    : context.palette.accent,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          value: task.subtasksProgress,
                          minHeight: 8,
                          backgroundColor: context.palette.surfaceSecondary,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            task.completedSubtasksCount == task.totalSubtasksCount
                                ? AppColors.success
                                : context.palette.accent,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Llevas ${task.completedSubtasksCount}/${task.totalSubtasksCount} subtareas completadas',
                            style: TextStyle(
                              color: context.palette.secondaryText,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          if (task.completedSubtasksCount == task.totalSubtasksCount &&
                              task.totalSubtasksCount > 0)
                            const Row(
                              children: [
                                Icon(
                                  PhosphorIconsBold.checkCircle,
                                  size: 14,
                                  color: AppColors.success,
                                ),
                                SizedBox(width: 4),
                                Text(
                                  '¡Completadas!',
                                  style: TextStyle(
                                    color: AppColors.success,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],

              // Subtasks Section header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Subtareas',
                    style: TextStyle(
                      color: context.palette.primaryText,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: _showAddSubtaskDialog,
                    icon: Icon(
                      PhosphorIconsRegular.plus,
                      size: 16,
                      color: context.palette.accent,
                    ),
                    label: Text(
                      'Agregar',
                      style: TextStyle(
                        color: context.palette.accent,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              if (task.subtasks.isEmpty) ...[
                AppCard(
                  padding: const EdgeInsets.all(20),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(
                          PhosphorIconsRegular.listChecks,
                          size: 28,
                          color: context.palette.secondaryText,
                        ),
                        SizedBox(height: 8),
                        Text(
                          'No hay subtareas registradas',
                          style: TextStyle(
                            color: context.palette.secondaryText,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ] else ...[
                ...task.subtasks.map(
                  (subtask) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: AppCard(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      child: Row(
                        children: [
                          GestureDetector(
                            onTap: () {
                              ref
                                  .read(
                                    taskDetailViewModelProvider(
                                      widget.taskId,
                                    ).notifier,
                                  )
                                  .toggleSubtask(
                                    subtask.id,
                                    !subtask.completed,
                                  );
                            },
                            child: Container(
                              width: 20,
                              height: 20,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: subtask.completed
                                      ? context.palette.onAccent
                                      : context.palette.secondaryText,
                                  width: 2,
                                ),
                                color: subtask.completed
                                    ? context.palette.accent
                                    : Colors.transparent,
                              ),
                              child: subtask.completed
                                  ? Center(
                                      child: Icon(
                                        PhosphorIconsBold.check,
                                        size: 10,
                                        color: context.palette.onAccent,
                                      ),
                                    )
                                  : null,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  subtask.title,
                                  style: TextStyle(
                                    color: subtask.completed
                                        ? context.palette.secondaryText
                                        : context.palette.primaryText,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    decoration: subtask.completed
                                        ? TextDecoration.lineThrough
                                        : null,
                                  ),
                                ),
                                if (subtask.description?.isNotEmpty == true) ...[
                                  const SizedBox(height: 3),
                                  Text(
                                    subtask.description!,
                                    style: TextStyle(
                                      color: context.palette.secondaryText,
                                      fontSize: 12,
                                      height: 1.3,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          IconButton(
                            icon: Icon(
                              PhosphorIconsRegular.trash,
                              size: 16,
                              color: context.palette.secondaryText,
                            ),
                            onPressed: () {
                              ref
                                  .read(
                                    taskDetailViewModelProvider(
                                      widget.taskId,
                                    ).notifier,
                                  )
                                  .deleteSubtask(subtask.id);
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
