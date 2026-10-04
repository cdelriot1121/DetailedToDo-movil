import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import '../../../app/theme.dart';
import '../../../core/utils/date_utils.dart';
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
    final notes = state.notes;

    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: AppBar(
        title: const Text('Notas'),
        actions: [
          IconButton(
            icon: const Icon(PhosphorIconsRegular.sparkle, size: 20),
            onPressed: () => context.push('/notes/ai'),
            tooltip: 'Resumir con IA',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.white,
        foregroundColor: AppColors.pureBlack,
        shape: const CircleBorder(),
        onPressed: () => context.push('/notes/new'),
        child: const Icon(PhosphorIconsRegular.plus, size: 24),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.white,
          backgroundColor: AppColors.primarySurface,
          onRefresh: () => ref.read(notesViewModelProvider.notifier).loadNotes(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Search Bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.primarySurface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: TextField(
                    onChanged: (value) {
                      // Optional search
                    },
                    style: const TextStyle(color: AppColors.primaryText, fontSize: 14),
                    decoration: const InputDecoration(
                      hintText: 'Buscar notas...',
                      prefixIcon: Icon(PhosphorIconsRegular.magnifyingGlass, color: AppColors.secondaryText, size: 18),
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                  ),
                ),
              ),

              // Filter Chips
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildCategoryChip(
                        ref,
                        label: 'Todas',
                        isSelected: state.selectedFolder == null,
                        folder: null,
                      ),
                      const SizedBox(width: 8),
                      _buildCategoryChip(
                        ref,
                        label: 'Estudio',
                        isSelected: state.selectedFolder == 'Estudio',
                        folder: 'Estudio',
                      ),
                      const SizedBox(width: 8),
                      _buildCategoryChip(
                        ref,
                        label: 'Ideas',
                        isSelected: state.selectedFolder == 'Ideas',
                        folder: 'Ideas',
                      ),
                      const SizedBox(width: 8),
                      _buildCategoryChip(
                        ref,
                        label: 'Trabajo',
                        isSelected: state.selectedFolder == 'Trabajo',
                        folder: 'Trabajo',
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),

              Expanded(
                child: state.isLoading && notes.isEmpty
                    ? const LoadingView(message: 'Cargando notas...')
                    : notes.isEmpty
                        ? const EmptyState(
                            icon: PhosphorIconsRegular.note,
                            title: 'No hay notas',
                            message: 'Crea una nueva nota para capturar tus ideas.',
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                            itemCount: notes.length,
                            separatorBuilder: (_, _) => const SizedBox(height: 12),
                            itemBuilder: (context, index) {
                              final note = notes[index];
                              return _buildNoteCard(context, note);
                            },
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryChip(
    WidgetRef ref, {
    required String label,
    required bool isSelected,
    required String? folder,
  }) {
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) {
        ref.read(notesViewModelProvider.notifier).setFilter(folder: folder);
      },
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

  Widget _buildNoteCard(BuildContext context, Note note) {
    return AppCard(
      onTap: () => context.push('/notes/${note.id}', extra: note),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  note.title,
                  style: const TextStyle(
                    color: AppColors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (note.folder != null && note.folder!.isNotEmpty) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.secondarySurface,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Text(
                    note.folder!,
                    style: const TextStyle(
                      color: AppColors.secondaryText,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 6),
          Text(
            note.content,
            style: const TextStyle(
              color: AppColors.secondaryText,
              fontSize: 13,
              height: 1.3,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              const Icon(PhosphorIconsRegular.clock, size: 12, color: AppColors.secondaryText),
              const SizedBox(width: 4),
              Text(
                AppDateUtils.formatShort(note.updatedAt ?? note.createdAt),
                style: const TextStyle(
                  color: AppColors.secondaryText,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
