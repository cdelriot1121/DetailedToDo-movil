import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import '../../../app/theme.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/loading_view.dart';
import '../models/note.dart';
import '../viewmodels/notes_view_model.dart';

class NotesScreen extends ConsumerWidget {
  const NotesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(notesViewModelProvider);

    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: AppBar(
        title: const Text('Notas'),
        actions: [
          IconButton(
            icon: const Icon(PhosphorIconsRegular.plus),
            onPressed: () async {
              await context.push('/notes/new');
              ref.read(notesViewModelProvider.notifier).loadNotes();
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Builder(
        builder: (context) {
          if (state.isLoading) {
            return const LoadingView(message: 'Cargando notas...');
          }

          if (state.viewState == NotesViewState.error) {
            return EmptyState(
              icon: PhosphorIconsRegular.warningCircle,
              title: 'Error al cargar notas',
              message: state.errorMessage,
              actionLabel: 'Reintentar',
              onAction: () =>
                  ref.read(notesViewModelProvider.notifier).loadNotes(),
              isError: true,
            );
          }

          if (state.isEmpty) {
            return EmptyState(
              icon: PhosphorIconsRegular.note,
              title: 'No hay notas',
              message: 'Crea notas libres para capturar tus pensamientos o usa la IA.',
              actionLabel: 'Crear nota',
              onAction: () async {
                await context.push('/notes/new');
                ref.read(notesViewModelProvider.notifier).loadNotes();
              },
            );
          }

          return RefreshIndicator(
            color: AppColors.white,
            backgroundColor: AppColors.primarySurface,
            onRefresh: () => ref
                .read(notesViewModelProvider.notifier)
                .loadNotes(isRefresh: true),
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              itemCount: state.notes.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final note = state.notes[index];
                return _NoteCard(
                  note: note,
                  onTap: () async {
                    await context.push('/notes/${note.id}', extra: note);
                    ref.read(notesViewModelProvider.notifier).loadNotes();
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

class _NoteCard extends StatelessWidget {
  final Note note;
  final VoidCallback onTap;

  const _NoteCard({
    required this.note,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  note.title,
                  style: const TextStyle(
                    color: AppColors.primaryText,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.2,
                  ),
                ),
              ),
              if (note.folder != null && note.folder!.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.secondarySurface,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Text(
                    note.folder!,
                    style: const TextStyle(
                      color: AppColors.secondaryText,
                      fontSize: 11,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            note.content,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.secondaryText,
              fontSize: 13,
              height: 1.4,
            ),
          ),
          if (note.tags.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              children: note.tags.map((tag) {
                return Text(
                  '#$tag',
                  style: const TextStyle(
                    color: AppColors.secondaryText,
                    fontSize: 11,
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }
}
