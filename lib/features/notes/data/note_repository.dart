import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../core/storage/local_storage_service.dart';
import '../../../core/sync/sync_service.dart';
import '../models/note.dart';
import 'note_api_service.dart';

final noteRepositoryProvider = Provider<NoteRepository>((ref) {
  final apiService = ref.watch(noteApiServiceProvider);
  final localStorage = ref.watch(localStorageServiceProvider);
  final syncService = ref.watch(syncServiceProvider);
  return NoteRepository(apiService, localStorage, syncService);
});

class NoteRepository {
  final NoteApiService _apiService;
  final LocalStorageService _localStorage;
  final SyncService _syncService;
  final _uuid = const Uuid();

  NoteRepository(
    this._apiService,
    this._localStorage,
    this._syncService,
  );

  Future<List<Note>> getNotes({
    String? folder,
    String? tag,
  }) async {
    try {
      final remoteNotes = await _apiService.getNotes(folder: folder, tag: tag);
      await _localStorage.saveNotes(remoteNotes);
      _syncService.syncPending().ignore();
      return remoteNotes;
    } catch (_) {
      return _localStorage.getNotes(folder: folder, tag: tag);
    }
  }

  Future<Note> getNote(String id) async {
    try {
      final remoteNote = await _apiService.getNote(id);
      await _localStorage.saveNote(remoteNote);
      return remoteNote;
    } catch (_) {
      final local = _localStorage.getNote(id);
      if (local != null) return local;
      rethrow;
    }
  }

  Future<Note> createNote({
    required String title,
    required String content,
    String? folder,
    String? color,
    List<String> tags = const [],
  }) async {
    final newId = _uuid.v4();
    final now = DateTime.now();

    final newNote = Note(
      id: newId,
      title: title,
      content: content,
      folder: folder,
      color: color,
      tags: tags,
      createdAt: now,
      updatedAt: now,
    );

    // Save locally immediately
    await _localStorage.saveNote(newNote);

    final payload = <String, dynamic>{
      'id': newId,
      'title': title,
      'content': content,
      'tags': tags,
    };
    if (folder != null && folder.isNotEmpty) {
      payload['folder'] = folder;
    }
    if (color != null && color.isNotEmpty) {
      payload['color'] = color;
    }

    // Register sync item
    await _localStorage.addSyncItem({
      'id': _uuid.v4(),
      'action': 'create_note',
      'resourceId': newId,
      'payload': payload,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });

    _syncService.syncPending().ignore();

    return newNote;
  }

  Future<Note> updateNote(
    String id, {
    required String title,
    required String content,
    String? folder,
    String? color,
    List<String>? tags,
  }) async {
    final existing = _localStorage.getNote(id);
    final updatedNote = (existing ?? Note(id: id, title: title, content: content)).copyWith(
      title: title,
      content: content,
      folder: folder,
      color: color,
      tags: tags,
      updatedAt: DateTime.now(),
    );

    // Save locally immediately
    await _localStorage.saveNote(updatedNote);

    final payload = <String, dynamic>{
      'title': title,
      'content': content,
    };
    if (folder != null) payload['folder'] = folder;
    if (color != null) payload['color'] = color;
    if (tags != null) payload['tags'] = tags;

    // Register sync item
    await _localStorage.addSyncItem({
      'id': _uuid.v4(),
      'action': 'update_note',
      'resourceId': id,
      'payload': payload,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });

    _syncService.syncPending().ignore();

    return updatedNote;
  }

  Future<void> deleteNote(String id) async {
    await _localStorage.deleteNote(id);

    await _localStorage.addSyncItem({
      'id': _uuid.v4(),
      'action': 'delete_note',
      'resourceId': id,
      'payload': {},
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });

    _syncService.syncPending().ignore();
  }

  Future<Note> createNoteWithAI(String content) async {
    final note = await _apiService.createNoteWithAI(content);
    await _localStorage.saveNote(note);
    return note;
  }
}
