import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/note.dart';
import 'note_api_service.dart';

final noteRepositoryProvider = Provider<NoteRepository>((ref) {
  final apiService = ref.watch(noteApiServiceProvider);
  return NoteRepository(apiService);
});

class NoteRepository {
  final NoteApiService _apiService;

  NoteRepository(this._apiService);

  Future<List<Note>> getNotes({
    String? folder,
    String? tag,
  }) async {
    return await _apiService.getNotes(folder: folder, tag: tag);
  }

  Future<Note> getNote(String id) async {
    return await _apiService.getNote(id);
  }

  Future<Note> createNote({
    required String title,
    required String content,
    String? folder,
    List<String> tags = const [],
  }) async {
    final payload = <String, dynamic>{
      'title': title,
      'content': content,
      'tags': tags,
    };
    if (folder != null && folder.isNotEmpty) {
      payload['folder'] = folder;
    }
    return await _apiService.createNote(payload);
  }

  Future<Note> updateNote(
    String id, {
    required String title,
    required String content,
    String? folder,
    List<String>? tags,
  }) async {
    final payload = <String, dynamic>{
      'title': title,
      'content': content,
    };
    if (folder != null) payload['folder'] = folder;
    if (tags != null) payload['tags'] = tags;

    return await _apiService.updateNote(id, payload);
  }

  Future<void> deleteNote(String id) async {
    await _apiService.deleteNote(id);
  }

  Future<Note> createNoteWithAI(String content) async {
    return await _apiService.createNoteWithAI(content);
  }
}
