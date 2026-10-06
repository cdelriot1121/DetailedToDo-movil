import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import '../../../app/theme.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/loading_view.dart';
import '../data/note_repository.dart';
import '../models/note.dart';
import '../viewmodels/notes_view_model.dart';

class NoteDetailScreen extends ConsumerStatefulWidget {
  final String noteId;
  final Note? initialNote;

  const NoteDetailScreen({super.key, required this.noteId, this.initialNote});

  @override
  ConsumerState<NoteDetailScreen> createState() => _NoteDetailScreenState();
}

class _NoteDetailScreenState extends ConsumerState<NoteDetailScreen> {
  Note? _note;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _note = widget.initialNote;
    if (_note == null) {
      _loadNote();
    }
  }

  Future<void> _loadNote() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final repository = ref.read(noteRepositoryProvider);
      final note = await repository.getNote(widget.noteId);
      setState(() {
        _note = note;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'No se pudo cargar la nota.';
        _isLoading = false;
      });
    }
  }

  void _confirmDelete() {
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
            '¿Eliminar nota?',
            style: TextStyle(color: AppColors.primaryText),
          ),
          content: const Text(
            'Esta nota se eliminará de forma permanente.',
            style: TextStyle(color: AppColors.secondaryText),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text(
                'Cancelar',
                style: TextStyle(color: AppColors.secondaryText),
              ),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(ctx);
                final deleted = await ref
                    .read(notesViewModelProvider.notifier)
                    .deleteNote(widget.noteId);
                if (deleted && mounted) {
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
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: AppColors.scaffoldBackground,
        body: LoadingView(message: 'Cargando nota...'),
      );
    }

    if (_errorMessage != null || _note == null) {
      return Scaffold(
        backgroundColor: AppColors.scaffoldBackground,
        appBar: AppBar(),
        body: EmptyState(
          icon: PhosphorIconsRegular.warningCircle,
          title: 'Error',
          message: _errorMessage,
          actionLabel: 'Reintentar',
          onAction: _loadNote,
          isError: true,
        ),
      );
    }

    final note = _note!;

    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: AppBar(
        title: const Text('Nota'),
        actions: [
          IconButton(
            icon: const Icon(PhosphorIconsRegular.pencilSimple),
            onPressed: () async {
              await context.push('/notes/${note.id}/edit', extra: note);
              _loadNote();
            },
          ),
          IconButton(
            icon: const Icon(PhosphorIconsRegular.trash),
            onPressed: _confirmDelete,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                note.title,
                style: const TextStyle(
                  color: AppColors.primaryText,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 12),

              if (note.folder != null && note.folder!.isNotEmpty) ...[
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.secondarySurface,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        PhosphorIconsRegular.folderSimple,
                        size: 14,
                        color: AppColors.secondaryText,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        note.folder!,
                        style: const TextStyle(
                          color: AppColors.primaryText,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              const Divider(),
              const SizedBox(height: 12),

              // Content Document Style
              Text(
                note.content,
                style: const TextStyle(
                  color: AppColors.primaryText,
                  fontSize: 15,
                  height: 1.6,
                ),
              ),

              if (note.tags.isNotEmpty) ...[
                const SizedBox(height: 28),
                Wrap(
                  spacing: 6,
                  children: note.tags.map((tag) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
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
            ],
          ),
        ),
      ),
    );
  }
}
