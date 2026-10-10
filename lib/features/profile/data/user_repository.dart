import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/storage/local_storage_service.dart';
import '../../../shared/models/ai_quota.dart';
import '../../auth/models/user.dart';

final userRepositoryProvider = Provider<UserRepository>((ref) {
  final dio = ref.watch(dioClientProvider);
  final localStorage = ref.watch(localStorageServiceProvider);
  return UserRepository(dio, localStorage);
});

class UserRepository {
  final Dio _dio;
  final LocalStorageService _localStorage;

  UserRepository(this._dio, this._localStorage);

  Future<User> getProfile() async {
    try {
      final response = await _dio.get('/users/me');
      final user = User.fromJson(response.data as Map<String, dynamic>);
      await _localStorage.saveUser(user);
      return user;
    } on DioException catch (e) {
      final cached = _localStorage.getUser();
      if (cached != null) return cached;
      throw ApiException.fromDioError(e);
    } catch (_) {
      final cached = _localStorage.getUser();
      if (cached != null) return cached;
      rethrow;
    }
  }

  Future<User> updateProfile({String? name, String? email}) async {
    try {
      final data = <String, dynamic>{};
      if (name != null) data['name'] = name;
      if (email != null) data['email'] = email;

      final response = await _dio.put('/users/me', data: data);
      final user = User.fromJson(response.data as Map<String, dynamic>);
      await _localStorage.saveUser(user);
      return user;
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<AIQuota> getAIQuota() async {
    try {
      final response = await _dio.get('/ai/quota');
      return AIQuota.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }
}
