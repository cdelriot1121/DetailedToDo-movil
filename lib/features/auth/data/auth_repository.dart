import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/storage/local_storage_service.dart';
import '../../../core/storage/secure_storage_service.dart';
import '../models/user.dart';
import 'auth_api_service.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final apiService = ref.watch(authApiServiceProvider);
  final storageService = ref.watch(secureStorageServiceProvider);
  final localStorage = ref.watch(localStorageServiceProvider);
  return AuthRepository(apiService, storageService, localStorage);
});

class AuthRepository {
  final AuthApiService _apiService;
  final SecureStorageService _storageService;
  final LocalStorageService _localStorage;

  AuthRepository(this._apiService, this._storageService, this._localStorage);

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

  Future<User> verifyOtp(String email, String code) async {
    final response = await _apiService.verifyOtp(email: email, code: code);
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

  Future<void> requestPasswordReset(String email) => _apiService.requestPasswordReset(email);
  Future<void> resendRegistrationOtp(String email) => _apiService.resendRegistrationOtp(email);

  Future<void> resetPassword(String email, String code, String newPassword) =>
      _apiService.resetPassword(email: email, code: code, newPassword: newPassword);

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
    await _localStorage.clearAllData();
  }

  Future<bool> isAuthenticated() async {
    final token = await _storageService.getToken();
    return token != null && token.isNotEmpty;
  }
}
