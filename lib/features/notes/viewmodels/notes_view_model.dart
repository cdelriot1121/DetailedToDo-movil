import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_exception.dart';
import '../data/note_repository.dart';
import '../models/note.dart';

enum NotesViewState {
  initial,
  loading,
  success,
  empty,
  error,
  refreshing,
}

class NotesState {
  final NotesViewState viewState;
  final List<Note> notes;
  final String? selectedFolder;
  final String? selectedTag;
  final String? errorMessage;

  const NotesState({
    this.viewState = NotesViewState.initial,
    this.notes = const [],
    this.selectedFolder,
    this.selectedTag,
    this.errorMessage,
  });

  bool get isLoading => viewState == NotesViewState.loading;
  bool get isEmpty => viewState == NotesViewState.empty;
  bool get hasFilters => selectedFolder != null || selectedTag != null;

  NotesState copyWith({
    NotesViewState? viewState,
    List<Note>? notes,
    String? selectedFolder,
    String? selectedTag,
    String? errorMessage,
    bool clearFolder = false,
    bool clearTag = false,
    bool clearError = false,
  }) {
    return NotesState(
      viewState: viewState ?? this.viewState,
      notes: notes ?? this.notes,
      selectedFolder: clearFolder ? null : (selectedFolder ?? this.selectedFolder),
      selectedTag: clearTag ? null : (selectedTag ?? this.selectedTag),
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

final notesViewModelProvider =
    NotifierProvider<NotesViewModel, NotesState>(NotesViewModel.new);

class NotesViewModel extends Notifier<NotesState> {
  NoteRepository get _repository => ref.read(noteRepositoryProvider);

  @override
  NotesState build() {
    Future.microtask(() => loadNotes());
    return const NotesState();
  }

  Future<void> loadNotes({bool isRefresh = false}) async {
    if (isRefresh) {
      state = state.copyWith(viewState: NotesViewState.refreshing, clearError: true);
    } else {
      state = state.copyWith(viewState: NotesViewState.loading, clearError: true);
    }

    try {
      final notes = await _repository.getNotes(
        folder: state.selectedFolder,
        tag: state.selectedTag,
      );

      if (notes.isEmpty) {
        state = state.copyWith(
          viewState: NotesViewState.empty,
          notes: [],
          clearError: true,
        );
      } else {
        state = state.copyWith(
          viewState: NotesViewState.success,
          notes: notes,
          clearError: true,
        );
      }
    } on ApiException catch (e) {
      state = state.copyWith(
        viewState: NotesViewState.error,
        errorMessage: e.message,
      );
    } catch (_) {
      state = state.copyWith(
        viewState: NotesViewState.error,
        errorMessage: 'Error al cargar las notas.',
      );
    }
  }

  void setFilter({String? folder, String? tag}) {
    state = state.copyWith(selectedFolder: folder, selectedTag: tag);
    loadNotes();
  }

  void clearFilters() {
    state = state.copyWith(clearFolder: true, clearTag: true);
    loadNotes();
  }

  Future<bool> createQuickNote({
    required String title,
    required String content,
    String? color,
    List<String> tags = const [],
  }) async {
    try {
      final newNote = await _repository.createNote(
        title: title,
        content: content,
        color: color,
        tags: tags,
      );
      state = state.copyWith(
        notes: [newNote, ...state.notes],
        viewState: NotesViewState.success,
      );
      return true;
    } catch (_) {
      // Fallback reload
      await loadNotes();
      return false;
    }
  }

  Future<bool> deleteNote(String id) async {
    try {
      await _repository.deleteNote(id);
      state = state.copyWith(
        notes: state.notes.where((n) => n.id != id).toList(),
      );
      if (state.notes.isEmpty) {
        state = state.copyWith(viewState: NotesViewState.empty);
      }
      return true;
    } catch (_) {
      return false;
    }
  }
}
