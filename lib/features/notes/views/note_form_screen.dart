import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import '../../../app/theme.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_text_field.dart';
import '../data/note_repository.dart';
import '../models/note.dart';
import '../viewmodels/notes_view_model.dart';

class NoteFormScreen extends ConsumerStatefulWidget {
  final Note? noteToEdit;

  const NoteFormScreen({super.key, this.noteToEdit});

  @override
  ConsumerState<NoteFormScreen> createState() => _NoteFormScreenState();
}

class _NoteFormScreenState extends ConsumerState<NoteFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _contentController;
  late final TextEditingController _folderController;
  late final TextEditingController _tagsController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final note = widget.noteToEdit;
    _titleController = TextEditingController(text: note?.title ?? '');
    _contentController = TextEditingController(text: note?.content ?? '');
    _folderController = TextEditingController(text: note?.folder ?? '');
    _tagsController = TextEditingController(text: note?.tags.join(', ') ?? '');
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _folderController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final repository = ref.read(noteRepositoryProvider);
    final tags = _tagsController.text
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    try {
      if (widget.noteToEdit != null) {
        await repository.updateNote(
          widget.noteToEdit!.id,
          title: _titleController.text.trim(),
          content: _contentController.text.trim(),
          folder: _folderController.text.trim().isEmpty
              ? null
              : _folderController.text.trim(),
          tags: tags,
        );
      } else {
        await repository.createNote(
          title: _titleController.text.trim(),
          content: _contentController.text.trim(),
          folder: _folderController.text.trim().isEmpty
              ? null
              : _folderController.text.trim(),
          tags: tags,
        );
      }

      ref.read(notesViewModelProvider.notifier).loadNotes();

      if (mounted) {
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al guardar nota: $e'),
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

  Future<void> _deleteNote() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('¿Eliminar nota?'),
        content: const Text('La nota se eliminará permanentemente.'),
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
    if (confirmed != true || widget.noteToEdit == null) return;
    final deleted = await ref
        .read(notesViewModelProvider.notifier)
        .deleteNote(widget.noteToEdit!.id);
    if (!mounted) return;
    if (deleted) {
      context.go('/notes');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo eliminar la nota.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.noteToEdit != null;

    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: AppBar(title: Text(isEditing ? 'Editar nota' : 'Nueva nota')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AppTextField(
                  label: 'Título',
                  controller: _titleController,
                  validator: (v) => Validators.requiredField(v, 'El título'),
                ),
                const SizedBox(height: 16),

                AppTextField(
                  label: 'Contenido',
                  controller: _contentController,
                  maxLines: 12,
                  minLines: 6,
                  validator: (v) => Validators.requiredField(v, 'El contenido'),
                ),
                const SizedBox(height: 16),

                AppTextField(
                  label: 'Carpeta (opcional)',
                  controller: _folderController,
                  prefixIcon: const Icon(
                    PhosphorIconsRegular.folderSimple,
                    color: AppColors.secondaryText,
                    size: 20,
                  ),
                ),
                const SizedBox(height: 16),

                AppTextField(
                  label: 'Etiquetas (separadas por comas)',
                  controller: _tagsController,
                  prefixIcon: const Icon(
                    PhosphorIconsRegular.tag,
                    color: AppColors.secondaryText,
                    size: 20,
                  ),
                ),
                const SizedBox(height: 32),

                AppButton(
                  label: isEditing ? 'Guardar cambios' : 'Crear nota',
                  isLoading: _isLoading,
                  onPressed: _save,
                  variant: AppButtonVariant.primary,
                ),
                if (isEditing) ...[
                  const SizedBox(height: 12),
                  AppButton(
                    label: 'Eliminar nota',
                    onPressed: _deleteNote,
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
}
