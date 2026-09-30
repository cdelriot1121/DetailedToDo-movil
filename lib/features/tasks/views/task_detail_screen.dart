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
import '../viewmodels/task_detail_view_model.dart';
import '../viewmodels/tasks_view_model.dart';

class TaskDetailScreen extends ConsumerStatefulWidget {
  final String taskId;

  const TaskDetailScreen({
    super.key,
    required this.taskId,
  });

  @override
  ConsumerState<TaskDetailScreen> createState() => _TaskDetailScreenState();
}

class _TaskDetailScreenState extends ConsumerState<TaskDetailScreen> {
  final _subtaskTextController = TextEditingController();

  @override
  void dispose() {
    _subtaskTextController.dispose();
    super.dispose();
  }

  void _showAddSubtaskDialog() {
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
            'Nueva subtarea',
            style: TextStyle(color: AppColors.white, fontSize: 18),
          ),
          content: TextField(
            controller: _subtaskTextController,
            autofocus: true,
            style: const TextStyle(color: AppColors.primaryText),
            decoration: const InputDecoration(
              hintText: 'Ej. Leer material preparatorio',
            ),
            onSubmitted: (value) async {
              if (value.trim().isNotEmpty) {
                Navigator.pop(ctx);
                await ref
                    .read(taskDetailViewModelProvider(widget.taskId).notifier)
                    .addSubtask(value.trim());
                _subtaskTextController.clear();
              }
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar', style: TextStyle(color: AppColors.secondaryText)),
            ),
            TextButton(
              onPressed: () async {
                final value = _subtaskTextController.text;
                if (value.trim().isNotEmpty) {
                  Navigator.pop(ctx);
                  await ref
                      .read(taskDetailViewModelProvider(widget.taskId).notifier)
                      .addSubtask(value.trim());
                  _subtaskTextController.clear();
                }
              },
              child: const Text('Agregar', style: TextStyle(color: AppColors.white, fontWeight: FontWeight.bold)),
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
          backgroundColor: AppColors.primarySurface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: const BorderSide(color: AppColors.border),
          ),
          title: const Text('¿Eliminar tarea?', style: TextStyle(color: AppColors.white)),
          content: const Text(
            'Esta acción eliminará la tarea y todas sus subtareas permanentemente.',
            style: TextStyle(color: AppColors.secondaryText),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar', style: TextStyle(color: AppColors.secondaryText)),
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
              child: const Text('Eliminar', style: TextStyle(color: AppColors.error, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(taskDetailViewModelProvider(widget.taskId));
    final notifier =
        ref.read(taskDetailViewModelProvider(widget.taskId).notifier);

    if (state.isLoading) {
      return const Scaffold(
        backgroundColor: AppColors.scaffoldBackground,
        body: LoadingView(message: 'Cargando tarea...'),
      );
    }

    if (state.errorMessage != null || state.task == null) {
      return Scaffold(
        backgroundColor: AppColors.scaffoldBackground,
        appBar: AppBar(),
        body: EmptyState(
          icon: PhosphorIconsRegular.warningCircle,
          title: 'No se pudo cargar la tarea',
          message: state.errorMessage,
          actionLabel: 'Reintentar',
          onAction: () => notifier.loadTask(),
          isError: true,
        ),
      );
    }

    final task = state.task!;
    final isDone = task.isCompleted;

    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: AppBar(
        title: const Text('Tarea'),
        actions: [
          IconButton(
            icon: const Icon(PhosphorIconsRegular.pencilSimple),
            onPressed: () async {
              await context.push('/tasks/${task.id}/edit', extra: task);
              notifier.loadTask();
            },
          ),
          IconButton(
            icon: const Icon(PhosphorIconsRegular.trash),
            onPressed: () => _confirmDeleteTask(context),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    Text(
                      task.title,
                      style: TextStyle(
                        color: isDone ? AppColors.disabledText : AppColors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.5,
                        decoration: isDone ? TextDecoration.lineThrough : null,
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Description
                    if (task.description != null &&
                        task.description!.trim().isNotEmpty) ...[
                      Text(
                        task.description!,
                        style: TextStyle(
                          color: isDone
                              ? AppColors.disabledText
                              : AppColors.secondaryText,
                          fontSize: 15,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Badges / Metadata
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _buildBadge(
                          icon: PhosphorIconsRegular.flag,
                          label: task.priority.label,
                          highlight: task.priority == TaskPriority.high,
                        ),
                        if (task.folder != null && task.folder!.isNotEmpty)
                          _buildBadge(
                            icon: PhosphorIconsRegular.folderSimple,
                            label: task.folder!,
                          ),
                        if (task.dueDate != null)
                          _buildBadge(
                            icon: PhosphorIconsRegular.calendarBlank,
                            label: AppDateUtils.formatShort(task.dueDate),
                          ),
                        if (task.reminderDate != null)
                          _buildBadge(
                            icon: PhosphorIconsRegular.bell,
                            label: AppDateUtils.formatShort(task.reminderDate),
                          ),
                      ],
                    ),

                    if (task.tags.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: task.tags.map((tag) {
                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.secondarySurface,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '#$tag',
                              style: const TextStyle(
                                color: AppColors.secondaryText,
                                fontSize: 12,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],

                    const Divider(height: 36),

                    // Subtasks Section Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Subtareas',
                          style: TextStyle(
                            color: AppColors.white,
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (task.subtasks.isNotEmpty)
                          Text(
                            '${task.completedSubtasksCount} de ${task.totalSubtasksCount}',
                            style: const TextStyle(
                              color: AppColors.secondaryText,
                              fontSize: 13,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // AI Generation status indicator
                    if (state.isPollingAI || task.isAIGenerating) ...[
                      AppCard(
                        backgroundColor: AppColors.secondarySurface,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        child: Row(
                          children: [
                            const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  AppColors.white,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Text(
                                'Generando subtareas con IA...',
                                style: TextStyle(
                                  color: AppColors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],

                    // Subtasks List
                    if (task.subtasks.isEmpty && !task.isAIGenerating) ...[
                      AppCard(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            const Text(
                              'No hay subtareas registradas',
                              style: TextStyle(
                                color: AppColors.secondaryText,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                OutlinedButton.icon(
                                  onPressed: () => notifier.requestAISubtasks(),
                                  icon: const Icon(
                                    PhosphorIconsRegular.sparkle,
                                    size: 16,
                                  ),
                                  label: const Text('Generar con IA'),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: AppColors.white,
                                    side: const BorderSide(
                                      color: AppColors.border,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ] else ...[
                      ...task.subtasks.map((subtask) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: AppCard(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                            child: Row(
                              children: [
                                GestureDetector(
                                  onTap: () {
                                    notifier.toggleSubtask(
                                      subtask.id,
                                      !subtask.completed,
                                    );
                                  },
                                  child: Container(
                                    width: 20,
                                    height: 20,
                                    decoration: BoxDecoration(
                                      color: subtask.completed
                                          ? AppColors.white
                                          : Colors.transparent,
                                      borderRadius: BorderRadius.circular(4),
                                      border: Border.all(
                                        color: subtask.completed
                                            ? AppColors.white
                                            : AppColors.secondaryText,
                                        width: 1.5,
                                      ),
                                    ),
                                    child: subtask.completed
                                        ? const Icon(
                                            PhosphorIconsBold.check,
                                            size: 14,
                                            color: AppColors.pureBlack,
                                          )
                                        : null,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    subtask.title,
                                    style: TextStyle(
                                      color: subtask.completed
                                          ? AppColors.disabledText
                                          : AppColors.primaryText,
                                      fontSize: 14,
                                      decoration: subtask.completed
                                          ? TextDecoration.lineThrough
                                          : null,
                                    ),
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(
                                    PhosphorIconsRegular.x,
                                    size: 16,
                                    color: AppColors.secondaryText,
                                  ),
                                  onPressed: () =>
                                      notifier.deleteSubtask(subtask.id),
                                ),
                              ],
                            ),
                          ),
                        );
                      }),
                    ],

                    const SizedBox(height: 8),
                    AppButton(
                      label: 'Nueva subtarea',
                      icon: PhosphorIconsRegular.plus,
                      variant: AppButtonVariant.secondary,
                      onPressed: _showAddSubtaskDialog,
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),

            // Bottom action bar (Toggle Complete)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: AppColors.primarySurface,
                border: Border(top: BorderSide(color: AppColors.border)),
              ),
              child: AppButton(
                label: isDone ? 'Marcar como pendiente' : 'Completar tarea',
                icon: isDone
                    ? PhosphorIconsRegular.arrowCounterClockwise
                    : PhosphorIconsBold.check,
                variant: isDone
                    ? AppButtonVariant.secondary
                    : AppButtonVariant.primary,
                onPressed: () => notifier.toggleStatus(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBadge({
    required IconData icon,
    required String label,
    bool highlight = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.secondarySurface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: highlight ? AppColors.white : AppColors.border,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: highlight ? AppColors.white : AppColors.secondaryText,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: highlight ? AppColors.white : AppColors.primaryText,
              fontSize: 12,
              fontWeight: highlight ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}
