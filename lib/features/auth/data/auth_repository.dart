import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_exception.dart';
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

    User user;
    if (response['user'] is Map<String, dynamic>) {
      user = User.fromJson(response['user'] as Map<String, dynamic>);
    } else {
      user = await _apiService.getCurrentUser();
    }
    await _localStorage.saveUser(user);
    return user;
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

    User user;
    if (response['user'] is Map<String, dynamic>) {
      user = User.fromJson(response['user'] as Map<String, dynamic>);
    } else {
      user = await _apiService.getCurrentUser();
    }
    await _localStorage.saveUser(user);
    return user;
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

    final cachedUser = _localStorage.getUser();

    try {
      final freshUser = await _apiService.getCurrentUser();
      await _localStorage.saveUser(freshUser);
      return freshUser;
    } on ApiException catch (e) {
      // Only clear token if unauthorized (401)
      if (e.statusCode == 401) {
        await _storageService.deleteToken();
        await _localStorage.deleteUser();
        return null;
      }
      // On network/timeout/offline errors, preserve session and return cached user
      if (cachedUser != null) {
        return cachedUser;
      }
      final email = await _storageService.getUserEmail() ?? '';
      return User(id: 'offline_user', name: email.split('@').first, email: email);
    } catch (_) {
      if (cachedUser != null) {
        return cachedUser;
      }
      final email = await _storageService.getUserEmail() ?? '';
      return User(id: 'offline_user', name: email.split('@').first, email: email);
    }
  }

  Future<User> getCurrentUser() async {
    try {
      final user = await _apiService.getCurrentUser();
      await _localStorage.saveUser(user);
      return user;
    } catch (_) {
      final cached = _localStorage.getUser();
      if (cached != null) return cached;
      final email = await _storageService.getUserEmail() ?? '';
      return User(id: 'offline_user', name: email.split('@').first, email: email);
    }
  }

  Future<User> updateProfile({String? name, String? email}) async {
    final user = await _apiService.updateCurrentUser(name: name, email: email);
    await _localStorage.saveUser(user);
    return user;
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
