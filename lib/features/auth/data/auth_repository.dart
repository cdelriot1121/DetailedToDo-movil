import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/storage/secure_storage_service.dart';
import '../models/user.dart';
import 'auth_api_service.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final apiService = ref.watch(authApiServiceProvider);
  final storageService = ref.watch(secureStorageServiceProvider);
  return AuthRepository(apiService, storageService);
});

class AuthRepository {
  final AuthApiService _apiService;
  final SecureStorageService _storageService;

  AuthRepository(this._apiService, this._storageService);

  Future<User> login(String email, String password) async {
    final response = await _apiService.login(email: email, password: password);
    final token = response['token'] as String?;
    if (token != null) {
      await _storageService.saveToken(token);
    }
    await _storageService.saveUserEmail(email);

    if (response['user'] is Map<String, dynamic>) {
      return User.fromJson(response['user'] as Map<String, dynamic>);
    }
    return await _apiService.getCurrentUser();
  }

  Future<void> register(String name, String email, String password) async {
    await _apiService.register(name: name, email: email, password: password);
  }

  Future<User?> checkAuth() async {
    final token = await _storageService.getToken();
    if (token == null || token.isEmpty) {
      return null;
    }
    try {
      return await _apiService.getCurrentUser();
    } catch (_) {
      await _storageService.deleteToken();
      return null;
    }
  }

  Future<User> getCurrentUser() async {
    return await _apiService.getCurrentUser();
  }

  Future<User> updateProfile({String? name, String? email}) async {
    return await _apiService.updateCurrentUser(name: name, email: email);
  }

  Future<void> logout() async {
    await _storageService.clearAll();
  }

  Future<bool> isAuthenticated() async {
    final token = await _storageService.getToken();
    return token != null && token.isNotEmpty;
  }
}
