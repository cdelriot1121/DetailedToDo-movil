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

class NotesScreen extends ConsumerStatefulWidget {
  const NotesScreen({super.key});

  @override
  ConsumerState<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends ConsumerState<NotesScreen> {
  bool _isGalleryView = true;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(notesViewModelProvider);
    final allNotes = state.notes;

    // Filter notes locally by search query if present
    final notes = _searchQuery.trim().isEmpty
        ? allNotes
        : allNotes.where((note) {
            final query = _searchQuery.toLowerCase();
            final titleMatch = note.title.toLowerCase().contains(query);
            final contentMatch = note.content.toLowerCase().contains(query);
            final folderMatch = note.folder?.toLowerCase().contains(query) ?? false;
            final tagsMatch = note.tags.any((t) => t.toLowerCase().contains(query));
            return titleMatch || contentMatch || folderMatch || tagsMatch;
          }).toList();

    // Extract dynamic folders from loaded notes
    final Set<String> dynamicFolders = {};
    for (final n in allNotes) {
      if (n.folder != null && n.folder!.trim().isNotEmpty) {
        dynamicFolders.add(n.folder!.trim());
      }
    }
    // Also add defaults if not present
    const defaultFolders = ['Estudio', 'Ideas', 'Trabajo'];
    for (final df in defaultFolders) {
      dynamicFolders.add(df);
    }
    final folderList = dynamicFolders.toList()..sort();

    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: AppBar(
        title: const Text('Notas'),
        actions: [
          // View Mode Switcher: Gallery vs List
          IconButton(
            icon: Icon(
              _isGalleryView
                  ? PhosphorIconsRegular.listDashes
                  : PhosphorIconsRegular.squaresFour,
              size: 22,
            ),
            tooltip: _isGalleryView ? 'Vista de lista' : 'Vista de galería',
            onPressed: () {
              setState(() {
                _isGalleryView = !_isGalleryView;
              });
            },
          ),
          IconButton(
            icon: const Icon(PhosphorIconsRegular.sparkle, size: 20),
            onPressed: () => context.push('/notes/ai'),
            tooltip: 'Crear / Resumir con IA',
          ),
          const SizedBox(width: 4),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.nearBlack,
        foregroundColor: AppColors.white,
        shape: const CircleBorder(),
        onPressed: () => context.push('/notes/new'),
        child: const Icon(PhosphorIconsRegular.plus, size: 24),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.nearBlack,
          backgroundColor: AppColors.primarySurface,
          onRefresh: () =>
              ref.read(notesViewModelProvider.notifier).loadNotes(isRefresh: true),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Search Bar & AI Action
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppColors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: TextField(
                          controller: _searchController,
                          onChanged: (value) {
                            setState(() {
                              _searchQuery = value;
                            });
                          },
                          style: const TextStyle(
                            color: AppColors.primaryText,
                            fontSize: 14,
                          ),
                          decoration: InputDecoration(
                            hintText: 'Buscar notas o etiquetas...',
                            hintStyle: const TextStyle(
                              color: AppColors.disabledText,
                              fontSize: 14,
                            ),
                            prefixIcon: const Icon(
                              PhosphorIconsRegular.magnifyingGlass,
                              color: AppColors.secondaryText,
                              size: 18,
                            ),
                            suffixIcon: _searchQuery.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(
                                      PhosphorIconsRegular.xCircle,
                                      size: 16,
                                      color: AppColors.secondaryText,
                                    ),
                                    onPressed: () {
                                      _searchController.clear();
                                      setState(() {
                                        _searchQuery = '';
                                      });
                                    },
                                  )
                                : null,
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.nearBlack,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: IconButton(
                        icon: const Icon(
                          PhosphorIconsRegular.sparkle,
                          color: AppColors.white,
                          size: 20,
                        ),
                        onPressed: () => context.push('/notes/ai'),
                        tooltip: 'Crear con IA',
                      ),
                    ),
                  ],
                ),
              ),

              // Dynamic Category / Folder Filter Chips
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildCategoryChip(
                        label: 'Todas',
                        count: allNotes.length,
                        isSelected: state.selectedFolder == null,
                        onTap: () {
                          ref
                              .read(notesViewModelProvider.notifier)
                              .setFilter(folder: null);
                        },
                      ),
                      const SizedBox(width: 8),
                      ...folderList.map((folder) {
                        final count =
                            allNotes.where((n) => n.folder == folder).length;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: _buildCategoryChip(
                            label: folder,
                            count: count > 0 ? count : null,
                            isSelected: state.selectedFolder == folder,
                            onTap: () {
                              ref
                                  .read(notesViewModelProvider.notifier)
                                  .setFilter(
                                    folder: state.selectedFolder == folder
                                        ? null
                                        : folder,
                                  );
                            },
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 10),

              // View stats bar: Showing count & current mode indicator
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 2),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${notes.length} ${notes.length == 1 ? 'nota' : 'notas'}${state.selectedFolder != null ? ' en ${state.selectedFolder}' : ''}',
                      style: const TextStyle(
                        color: AppColors.secondaryText,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Row(
                      children: [
                        Text(
                          _isGalleryView ? 'Galería' : 'Lista',
                          style: const TextStyle(
                            color: AppColors.secondaryText,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          _isGalleryView
                              ? PhosphorIconsRegular.squaresFour
                              : PhosphorIconsRegular.listDashes,
                          size: 14,
                          color: AppColors.secondaryText,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 6),

              // Notes List / Gallery Content
              Expanded(
                child: state.isLoading && allNotes.isEmpty
                    ? const LoadingView(message: 'Cargando notas...')
                    : notes.isEmpty
                    ? EmptyState(
                        icon: _searchQuery.isNotEmpty
                            ? PhosphorIconsRegular.magnifyingGlass
                            : PhosphorIconsRegular.note,
                        title: _searchQuery.isNotEmpty
                            ? 'Sin resultados'
                            : 'No hay notas aún',
                        message: _searchQuery.isNotEmpty
                            ? 'No encontramos notas que coincidan con "$_searchQuery".'
                            : 'Crea una nueva nota o genera una con Inteligencia Artificial.',
                      )
                    : _isGalleryView
                    ? _buildGalleryLayout(notes)
                    : _buildListLayout(notes),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryChip({
    required String label,
    int? count,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return ChoiceChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label),
          if (count != null) ...[
            const SizedBox(width: 5),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.nearBlack.withValues(alpha: 0.12)
                    : AppColors.secondaryText.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? AppColors.pureBlack : AppColors.secondaryText,
                ),
              ),
            ),
          ],
        ],
      ),
      selected: isSelected,
      onSelected: (_) => onTap(),
      selectedColor: AppColors.lightSurfaceSecondary,
      backgroundColor: AppColors.secondarySurface,
      labelStyle: TextStyle(
        color: isSelected ? AppColors.pureBlack : AppColors.primaryText,
        fontSize: 13,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: isSelected ? AppColors.nearBlack : AppColors.border,
        ),
      ),
    );
  }

  // Gallery View: Masonry / 2-column Pinterest style
  Widget _buildGalleryLayout(List<Note> notes) {
    final leftNotes = <Note>[];
    final rightNotes = <Note>[];

    for (int i = 0; i < notes.length; i++) {
      if (i.isEven) {
        leftNotes.add(notes[i]);
      } else {
        rightNotes.add(notes[i]);
      }
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              children: leftNotes
                  .map((note) => _buildGalleryCard(note))
                  .toList(),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              children: rightNotes
                  .map((note) => _buildGalleryCard(note))
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGalleryCard(Note note) {
    final date = note.updatedAt ?? note.createdAt;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxStyle.softShadow,
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => context.push('/notes/${note.id}', extra: note),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top row: Folder or Tag badge
                if (note.folder != null && note.folder!.isNotEmpty) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
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
                              size: 11,
                              color: AppColors.secondaryText,
                            ),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                note.folder!,
                                style: const TextStyle(
                                  color: AppColors.primaryText,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                ],

                // Title
                Text(
                  note.title.isNotEmpty ? note.title : 'Sin título',
                  style: const TextStyle(
                    color: AppColors.primaryText,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.3,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),

                // Content preview
                if (note.content.isNotEmpty)
                  Text(
                    note.content,
                    style: const TextStyle(
                      color: AppColors.secondaryText,
                      fontSize: 13,
                      height: 1.35,
                    ),
                    maxLines: 4,
                    overflow: TextOverflow.ellipsis,
                  ),

                // Tags in gallery card
                if (note.tags.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 4,
                    runSpacing: 4,
                    children: note.tags.take(2).map((tag) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.lightSurfaceSecondary,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          tag.startsWith('#') ? tag : '#$tag',
                          style: const TextStyle(
                            color: AppColors.secondaryText,
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],

                const SizedBox(height: 12),
                // Footer: Date
                Row(
                  children: [
                    const Icon(
                      PhosphorIconsRegular.clock,
                      size: 11,
                      color: AppColors.disabledText,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      date != null ? AppDateUtils.formatShort(date) : '',
                      style: const TextStyle(
                        color: AppColors.disabledText,
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // List View: Sleek Horizontal row cards
  Widget _buildListLayout(List<Note> notes) {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      itemCount: notes.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final note = notes[index];
        return _buildListCard(note);
      },
    );
  }

  Widget _buildListCard(Note note) {
    final date = note.updatedAt ?? note.createdAt;

    return AppCard(
      onTap: () => context.push('/notes/${note.id}', extra: note),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  note.title.isNotEmpty ? note.title : 'Sin título',
                  style: const TextStyle(
                    color: AppColors.primaryText,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.3,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (note.folder != null && note.folder!.isNotEmpty) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
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
                        size: 11,
                        color: AppColors.secondaryText,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        note.folder!,
                        style: const TextStyle(
                          color: AppColors.primaryText,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
          if (note.content.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              note.content,
              style: const TextStyle(
                color: AppColors.secondaryText,
                fontSize: 13,
                height: 1.35,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (note.tags.isNotEmpty)
                Expanded(
                  child: Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: note.tags.take(3).map((tag) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.lightSurfaceSecondary,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          tag.startsWith('#') ? tag : '#$tag',
                          style: const TextStyle(
                            color: AppColors.secondaryText,
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                )
              else
                const Spacer(),
              Row(
                children: [
                  const Icon(
                    PhosphorIconsRegular.clock,
                    size: 12,
                    color: AppColors.secondaryText,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    date != null ? AppDateUtils.formatShort(date) : '',
                    style: const TextStyle(
                      color: AppColors.secondaryText,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class BoxStyle {
  static BoxShadow softShadow = BoxShadow(
    color: Colors.black.withValues(alpha: 0.03),
    blurRadius: 10,
    offset: const Offset(0, 4),
  );
}
