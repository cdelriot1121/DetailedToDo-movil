import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import '../../../app/theme.dart';
import '../../../core/utils/date_utils.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_text_field.dart';
import '../data/event_repository.dart';
import '../models/event.dart';
import '../viewmodels/events_view_model.dart';

class EventFormScreen extends ConsumerStatefulWidget {
  final Event? eventToEdit;

  const EventFormScreen({super.key, this.eventToEdit});

  @override
  ConsumerState<EventFormScreen> createState() => _EventFormScreenState();
}

class _EventFormScreenState extends ConsumerState<EventFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _locationController;

  late DateTime _startDate;
  DateTime? _endDate;
  DateTime? _reminderDate;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final event = widget.eventToEdit;
    _titleController = TextEditingController(text: event?.title ?? '');
    _descriptionController = TextEditingController(
      text: event?.description ?? '',
    );
    _locationController = TextEditingController(text: event?.location ?? '');
    _startDate =
        event?.startDate ?? DateTime.now().add(const Duration(hours: 1));
    _endDate = event?.endDate;
    _reminderDate = event?.reminderDate;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _pickDateTime({required int type}) async {
    // type: 0 -> start, 1 -> end, 2 -> reminder
    final initialDate = type == 0
        ? _startDate
        : (type == 1
              ? (_endDate ?? _startDate)
              : (_reminderDate ?? _startDate));

    final pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.nearBlack,
              onPrimary: AppColors.white,
              surface: AppColors.white,
              onSurface: AppColors.primaryText,
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedDate == null || !mounted) return;

    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initialDate),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.nearBlack,
              onPrimary: AppColors.white,
              surface: AppColors.white,
              onSurface: AppColors.primaryText,
            ),
          ),
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
      if (type == 0) {
        _startDate = result;
      } else if (type == 1) {
        _endDate = result;
      } else {
        _reminderDate = result;
      }
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final repository = ref.read(eventRepositoryProvider);

    try {
      if (widget.eventToEdit != null) {
        await repository.updateEvent(
          widget.eventToEdit!.id,
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim().isEmpty
              ? null
              : _descriptionController.text.trim(),
          startDate: _startDate,
          endDate: _endDate,
          location: _locationController.text.trim().isEmpty
              ? null
              : _locationController.text.trim(),
          reminderDate: _reminderDate,
          tags: widget.eventToEdit?.tags ?? [],
        );
      } else {
        await repository.createEvent(
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim().isEmpty
              ? null
              : _descriptionController.text.trim(),
          startDate: _startDate,
          endDate: _endDate,
          location: _locationController.text.trim().isEmpty
              ? null
              : _locationController.text.trim(),
          reminderDate: _reminderDate,
        );
      }

      ref.read(eventsViewModelProvider.notifier).loadEvents();

      if (mounted) {
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al guardar evento: $e'),
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

  Future<void> _deleteEvent() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('¿Eliminar evento?'),
        content: const Text('El evento se eliminará permanentemente.'),
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
    if (confirmed != true || widget.eventToEdit == null) return;
    final deleted = await ref
        .read(eventsViewModelProvider.notifier)
        .deleteEvent(widget.eventToEdit!.id);
    if (!mounted) return;
    if (deleted) {
      context.go('/events');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo eliminar el evento.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.eventToEdit != null;

    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: AppBar(title: Text(isEditing ? 'Editar evento' : 'Nuevo evento')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AppTextField(
                  label: 'Título del evento',
                  controller: _titleController,
                  validator: (v) => Validators.requiredField(v, 'El título'),
                ),
                const SizedBox(height: 16),

                AppTextField(
                  label: 'Descripción (opcional)',
                  controller: _descriptionController,
                  maxLines: 3,
                ),
                const SizedBox(height: 20),

                // Start Date Picker
                _buildPickerTile(
                  icon: PhosphorIconsRegular.calendarBlank,
                  title: 'Fecha y hora de inicio',
                  value: AppDateUtils.formatFull(_startDate),
                  onTap: () => _pickDateTime(type: 0),
                ),
                const SizedBox(height: 12),

                // End Date Picker
                _buildPickerTile(
                  icon: PhosphorIconsRegular.calendarCheck,
                  title: 'Fecha y hora de fin (opcional)',
                  value: _endDate != null
                      ? AppDateUtils.formatFull(_endDate)
                      : 'Sin fecha de fin',
                  onTap: () => _pickDateTime(type: 1),
                  onClear: _endDate != null
                      ? () => setState(() => _endDate = null)
                      : null,
                ),
                const SizedBox(height: 12),

                // Reminder Date Picker
                _buildPickerTile(
                  icon: PhosphorIconsRegular.bell,
                  title: 'Recordatorio (opcional)',
                  value: _reminderDate != null
                      ? AppDateUtils.formatFull(_reminderDate)
                      : 'Sin recordatorio',
                  onTap: () => _pickDateTime(type: 2),
                  onClear: _reminderDate != null
                      ? () => setState(() => _reminderDate = null)
                      : null,
                ),
                const SizedBox(height: 20),

                // Location
                AppTextField(
                  label: 'Ubicación o enlace (opcional)',
                  controller: _locationController,
                  prefixIcon: const Icon(
                    PhosphorIconsRegular.mapPin,
                    color: AppColors.secondaryText,
                    size: 20,
                  ),
                ),
                const SizedBox(height: 32),

                AppButton(
                  label: isEditing ? 'Guardar cambios' : 'Crear evento',
                  isLoading: _isLoading,
                  onPressed: _save,
                  variant: AppButtonVariant.primary,
                ),
                if (isEditing) ...[
                  const SizedBox(height: 12),
                  AppButton(
                    label: 'Eliminar evento',
                    onPressed: _deleteEvent,
                    variant: AppButtonVariant.secondary,
                  ),
                ],
              ],
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
          color: AppColors.inputBackground,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: AppColors.secondaryText),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
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
                    ),
                  ),
                ],
              ),
            ),
            if (onClear != null)
              IconButton(
                icon: const Icon(
                  PhosphorIconsRegular.x,
                  size: 16,
                  color: AppColors.secondaryText,
                ),
                onPressed: onClear,
              )
            else
              const Icon(
                PhosphorIconsRegular.caretRight,
                size: 16,
                color: AppColors.secondaryText,
              ),
          ],
        ),
      ),
    );
  }
}
