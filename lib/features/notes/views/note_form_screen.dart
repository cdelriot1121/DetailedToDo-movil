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
  int _section = 0;

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

  void _insertMarkdown(String before, [String after = '']) {
    final value = _contentController.value;
    final selection = value.selection;
    final start = selection.isValid ? selection.start : value.text.length;
    final end = selection.isValid ? selection.end : value.text.length;
    final selected = value.text.substring(start, end);
    final inserted = '$before${selected.isEmpty ? 'texto' : selected}$after';
    _contentController.value = TextEditingValue(
      text: value.text.replaceRange(start, end, inserted),
      selection: TextSelection.collapsed(offset: start + inserted.length),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      setState(() => _section = 0);
      return;
    }
    setState(() => _isLoading = true);
    final tags = _tagsController.text.split(',').map((tag) => tag.trim()).where((tag) => tag.isNotEmpty).toList();
    try {
      if (widget.noteToEdit case final note?) {
        final repository = ref.read(noteRepositoryProvider);
        await repository.updateNote(note.id, title: _titleController.text.trim(), content: _contentController.text.trim(), folder: _folderController.text.trim().isEmpty ? null : _folderController.text.trim(), tags: tags);
        await ref.read(notesViewModelProvider.notifier).loadNotes();
      } else {
        final created = await ref.read(notesViewModelProvider.notifier).createQuickNote(
          title: _titleController.text.trim(),
          content: _contentController.text.trim(),
          folder: _folderController.text.trim().isEmpty ? null : _folderController.text.trim(),
          tags: tags,
        );
        if (!created) throw Exception('No se pudo guardar la nota localmente.');
      }
      if (mounted) context.pop();
    } catch (error) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error al guardar nota: $error'), backgroundColor: AppColors.error));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteNote() async {
    final confirmed = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(
      title: const Text('¿Eliminar nota?'), content: const Text('La nota se eliminará permanentemente.'),
      actions: [TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')), TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Eliminar', style: TextStyle(color: AppColors.error)))],
    ));
    if (confirmed != true || widget.noteToEdit == null) return;
    final deleted = await ref.read(notesViewModelProvider.notifier).deleteNote(widget.noteToEdit!.id);
    if (!mounted) return;
    if (deleted) { context.go('/notes'); } else { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No se pudo eliminar la nota.'))); }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.noteToEdit != null;
    return Scaffold(
      backgroundColor: context.palette.scaffoldBackground,
      appBar: AppBar(title: Text(isEditing ? 'Editar nota' : 'Nueva nota')),
      body: SafeArea(child: Form(key: _formKey, child: Column(children: [
        Padding(padding: const EdgeInsets.fromLTRB(20, 12, 20, 0), child: SegmentedButton<int>(
          segments: const [ButtonSegment(value: 0, label: Text('Contenido'), icon: Icon(Icons.article_outlined)), ButtonSegment(value: 1, label: Text('Propiedades'), icon: Icon(Icons.tune))],
          selected: {_section}, onSelectionChanged: (value) => setState(() => _section = value.first),
        )),
        Expanded(child: SingleChildScrollView(padding: const EdgeInsets.all(20), child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          if (_section == 0) ...[
            AppTextField(label: 'Título', controller: _titleController, validator: (v) => Validators.requiredField(v, 'El título')),
            const SizedBox(height: 14),
            Text('Formato', style: TextStyle(color: context.palette.secondaryText, fontSize: 12)),
            Wrap(spacing: 2, children: [
              IconButton(tooltip: 'Encabezado', onPressed: () => _insertMarkdown('## '), icon: const Icon(Icons.title)),
              IconButton(tooltip: 'Negrita', onPressed: () => _insertMarkdown('**', '**'), icon: const Icon(Icons.format_bold)),
              IconButton(tooltip: 'Cursiva', onPressed: () => _insertMarkdown('*', '*'), icon: const Icon(Icons.format_italic)),
              IconButton(tooltip: 'Lista', onPressed: () => _insertMarkdown('- '), icon: const Icon(Icons.format_list_bulleted)),
              IconButton(tooltip: 'Cita', onPressed: () => _insertMarkdown('> '), icon: const Icon(Icons.format_quote)),
            ]),
            AppTextField(label: 'Contenido en Markdown', controller: _contentController, maxLines: 24, minLines: 14, hint: 'Usa # para títulos, **texto** para negrita y - para listas.', validator: (v) => Validators.requiredField(v, 'El contenido')),
            const SizedBox(height: 8),
            Text('Puedes escribir Markdown directamente o seleccionar texto y aplicar formato.', style: TextStyle(color: context.palette.secondaryText, fontSize: 12)),
          ] else ...[
            Text('Propiedades de la nota', style: TextStyle(color: context.palette.primaryText, fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('Clasifica y encuentra tu nota fácilmente.', style: TextStyle(color: context.palette.secondaryText)),
            const SizedBox(height: 24),
            AppTextField(label: 'Carpeta (opcional)', controller: _folderController, prefixIcon: Icon(PhosphorIconsRegular.folderSimple, color: context.palette.secondaryText, size: 20)),
            const SizedBox(height: 16),
            AppTextField(label: 'Etiquetas (separadas por comas)', controller: _tagsController, prefixIcon: Icon(PhosphorIconsRegular.tag, color: context.palette.secondaryText, size: 20)),
          ],
          if (isEditing) ...[const SizedBox(height: 32), AppButton(label: 'Eliminar nota', onPressed: _deleteNote, variant: AppButtonVariant.secondary)],
        ]))),
      ]))),
      bottomNavigationBar: SafeArea(minimum: const EdgeInsets.fromLTRB(20, 8, 20, 16), child: AppButton(label: isEditing ? 'Guardar cambios' : 'Crear nota', isLoading: _isLoading, onPressed: _save, variant: AppButtonVariant.primary)),
    );
  }
}
