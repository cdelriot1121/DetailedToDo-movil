import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/network/dio_client.dart';
import '../models/note.dart';

final noteApiServiceProvider = Provider<NoteApiService>((ref) {
  final dio = ref.watch(dioClientProvider);
  return NoteApiService(dio);
});

class NoteApiService {
  final Dio _dio;

  NoteApiService(this._dio);

  Future<List<Note>> getNotes({
    String? folder,
    String? tag,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (folder != null && folder.isNotEmpty) queryParams['folder'] = folder;
      if (tag != null && tag.isNotEmpty) queryParams['tag'] = tag;

      final response = await _dio.get(
        '/notes',
        queryParameters: queryParams.isEmpty ? null : queryParams,
      );

      final data = response.data;
      if (data is List) {
        return data
            .map((item) => Note.fromJson(item as Map<String, dynamic>))
            .toList();
      }
      return [];
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<Note> getNote(String id) async {
    try {
      final response = await _dio.get('/notes/$id');
      return Note.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<Note> createNote(Map<String, dynamic> noteData) async {
    try {
      final response = await _dio.post('/notes', data: noteData);
      return Note.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<Note> updateNote(String id, Map<String, dynamic> noteData) async {
    try {
      final response = await _dio.put('/notes/$id', data: noteData);
      return Note.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<void> deleteNote(String id) async {
    try {
      await _dio.delete('/notes/$id');
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<Note> createNoteWithAI(String content) async {
    try {
      final response = await _dio.post(
        '/notes/ai',
        data: {'content': content},
      );
      return Note.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }
}
