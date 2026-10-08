import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import '../../../app/theme.dart';
import '../../../core/utils/date_utils.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_text_field.dart';
import '../data/task_repository.dart';
import '../models/task.dart';
import '../viewmodels/tasks_view_model.dart';

class TaskFormScreen extends ConsumerStatefulWidget {
  final Task? taskToEdit;

  const TaskFormScreen({super.key, this.taskToEdit});

  @override
  ConsumerState<TaskFormScreen> createState() => _TaskFormScreenState();
}

class _TaskFormScreenState extends ConsumerState<TaskFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _folderController;
  late final TextEditingController _tagsController;

  late TaskPriority _priority;
  late bool _isCompleted;
  DateTime? _dueDate;
  DateTime? _reminderDate;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final task = widget.taskToEdit;
    _titleController = TextEditingController(text: task?.title ?? '');
    _descriptionController = TextEditingController(
      text: task?.description ?? '',
    );
    _folderController = TextEditingController(text: task?.folder ?? '');
    _tagsController = TextEditingController(text: task?.tags.join(', ') ?? '');
    _priority = task?.priority ?? TaskPriority.medium;
    _isCompleted = task?.status == TaskStatus.completed;
    _dueDate = task?.dueDate;
    _reminderDate = task?.reminderDate;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _folderController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  Future<void> _pickDateTime({required bool isReminder}) async {
    final now = DateTime.now();
    final initialDate = isReminder ? (_reminderDate ?? now) : (_dueDate ?? now);

    final pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: now.subtract(const Duration(days: 365)),
      lastDate: now.add(const Duration(days: 365 * 5)),
      builder: (context, child) {
        // El selector de fecha/hora respeta el tema activo.
        return Theme(
          data: AppTheme.fromPalette(context.palette),
          child: child!,
        );
      },
    );

    if (pickedDate == null || !mounted) return;

    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initialDate),
      builder: (context, child) {
        // El selector de fecha/hora respeta el tema activo.
        return Theme(
          data: AppTheme.fromPalette(context.palette),
          child: child!,
        );
      },
    );

    if (pickedTime == null || !mounted) return;

    final result = DateTime(
      pickedDate.year,
      pickedDate.month,
      pickedDate.day,
      pickedTime.hour,
      pickedTime.minute,
    );

    setState(() {
      if (isReminder) {
        _reminderDate = result;
      } else {
        _dueDate = result;
      }
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final repository = ref.read(taskRepositoryProvider);
    final tags = _tagsController.text
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    try {
      if (widget.taskToEdit != null) {
        await repository.updateTask(
          widget.taskToEdit!.id,
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim().isEmpty
              ? null
              : _descriptionController.text.trim(),
          status: _isCompleted ? TaskStatus.completed : TaskStatus.pending,
          priority: _priority,
          dueDate: _dueDate,
          reminderDate: _reminderDate,
          folder: _folderController.text.trim().isEmpty
              ? null
              : _folderController.text.trim(),
          tags: tags,
        );
      } else {
        await repository.createTask(
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim().isEmpty
              ? null
              : _descriptionController.text.trim(),
          priority: _priority,
          dueDate: _dueDate,
          reminderDate: _reminderDate,
          folder: _folderController.text.trim().isEmpty
              ? null
              : _folderController.text.trim(),
          tags: tags,
        );
      }

      ref.read(tasksViewModelProvider.notifier).loadTasks();

      if (mounted) {
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al guardar tarea: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _deleteTask() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('¿Eliminar tarea?'),
        content: const Text('La tarea y sus subtareas se eliminarán.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text(
              'Eliminar',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true || widget.taskToEdit == null) return;
    final deleted = await ref
        .read(tasksViewModelProvider.notifier)
        .deleteTask(widget.taskToEdit!.id);
    if (!mounted) return;
    if (deleted) {
      context.go('/tasks');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo eliminar la tarea.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.taskToEdit != null;

    return Scaffold(
      backgroundColor: context.palette.scaffoldBackground,
      appBar: AppBar(title: Text(isEditing ? 'Editar tarea' : 'Nueva tarea')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Title
                AppTextField(
                  label: 'Título de la tarea',
                  controller: _titleController,
                  validator: (v) => Validators.requiredField(v, 'El título'),
                ),
                const SizedBox(height: 16),

                // Description
                AppTextField(
                  label: 'Descripción (opcional)',
                  controller: _descriptionController,
                  maxLines: 4,
                  minLines: 2,
                ),
                const SizedBox(height: 20),

                // Priority Selector
                Text(
                  'Prioridad',
                  style: TextStyle(
                    color: context.palette.primaryText,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _buildPriorityButton(TaskPriority.low),
                    const SizedBox(width: 8),
                    _buildPriorityButton(TaskPriority.medium),
                    const SizedBox(width: 8),
                    _buildPriorityButton(TaskPriority.high),
                  ],
                ),
                const SizedBox(height: 20),

                if (isEditing) ...[
                  SwitchListTile.adaptive(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                    value: _isCompleted,
                    activeTrackColor: context.palette.accent,
                    title: const Text('Marcar como completada'),
                    onChanged: (value) => setState(() => _isCompleted = value),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                      side: BorderSide(color: context.palette.border),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],

                // Due Date Picker Tile
                _buildPickerTile(
                  icon: PhosphorIconsRegular.calendarBlank,
                  title: 'Fecha límite',
                  value: _dueDate != null
                      ? AppDateUtils.formatFull(_dueDate)
                      : 'Sin fecha límite',
                  onTap: () => _pickDateTime(isReminder: false),
                  onClear: _dueDate != null
                      ? () => setState(() => _dueDate = null)
                      : null,
                ),
                const SizedBox(height: 12),

                // Reminder Date Picker Tile
                _buildPickerTile(
                  icon: PhosphorIconsRegular.bell,
                  title: 'Recordatorio',
                  value: _reminderDate != null
                      ? AppDateUtils.formatFull(_reminderDate)
                      : 'Sin recordatorio',
                  onTap: () => _pickDateTime(isReminder: true),
                  onClear: _reminderDate != null
                      ? () => setState(() => _reminderDate = null)
                      : null,
                ),
                const SizedBox(height: 20),

                // Folder
                AppTextField(
                  label: 'Carpeta / Categoría (opcional)',
                  controller: _folderController,
                  prefixIcon: Icon(
                    PhosphorIconsRegular.folderSimple,
                    color: context.palette.secondaryText,
                    size: 20,
                  ),
                ),
                const SizedBox(height: 16),

                // Tags
                AppTextField(
                  label: 'Etiquetas (separadas por comas)',
                  controller: _tagsController,
                  prefixIcon: Icon(
                    PhosphorIconsRegular.tag,
                    color: context.palette.secondaryText,
                    size: 20,
                  ),
                ),
                const SizedBox(height: 32),

                // Submit Button
                AppButton(
                  label: isEditing ? 'Guardar cambios' : 'Crear tarea',
                  isLoading: _isLoading,
                  onPressed: _save,
                  variant: AppButtonVariant.primary,
                ),
                if (isEditing) ...[
                  const SizedBox(height: 12),
                  AppButton(
                    label: 'Eliminar tarea',
                    onPressed: _deleteTask,
                    variant: AppButtonVariant.secondary,
                  ),
                ],
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPriorityButton(TaskPriority p) {
    final isSelected = _priority == p;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _priority = p),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected
                ? context.palette.surfaceSecondary
                : context.palette.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected
                  ? context.palette.accent
                  : context.palette.border,
            ),
          ),
          child: Center(
            child: Text(
              p.label,
              style: TextStyle(
                color: isSelected
                    ? context.palette.accent
                    : context.palette.primaryText,
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPickerTile({
    required IconData icon,
    required String title,
    required String value,
    required VoidCallback onTap,
    VoidCallback? onClear,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: context.palette.inputBackground,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: context.palette.border),
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: context.palette.secondaryText),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: context.palette.secondaryText,
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: TextStyle(
                      color: context.palette.primaryText,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            if (onClear != null)
              IconButton(
                icon: Icon(
                  PhosphorIconsRegular.x,
                  size: 16,
                  color: context.palette.secondaryText,
                ),
                onPressed: onClear,
              )
            else
              Icon(
                PhosphorIconsRegular.caretRight,
                size: 16,
                color: context.palette.secondaryText,
              ),
          ],
        ),
      ),
    );
  }
}
