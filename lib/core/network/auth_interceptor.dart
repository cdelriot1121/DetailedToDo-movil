import 'package:dio/dio.dart';
import '../storage/secure_storage_service.dart';

class AuthInterceptor extends QueuedInterceptor {
  final SecureStorageService _storageService;
  final void Function()? onUnauthorized;

  AuthInterceptor(this._storageService, {this.onUnauthorized});

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    // Normalize path to prevent leading slash from stripping baseUrl's /api/ prefix
    if (options.path.startsWith('/')) {
      options.path = options.path.substring(1);
    }

    final path = options.path;
    final isAuthPublicEndpoint =
        path.contains('auth/login') || path.contains('auth/register');

    if (!isAuthPublicEndpoint) {
      final token = await _storageService.getToken();
      if (token != null && token.isNotEmpty) {
        options.headers['Authorization'] = 'Bearer $token';
      }
    }

    options.headers['Content-Type'] = 'application/json';
    options.headers['Accept'] = 'application/json';

    return handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    if (err.response?.statusCode == 401) {
      // Clear token on 401 Unauthorized
      await _storageService.deleteToken();
      onUnauthorized?.call();
    }
    return handler.next(err);
  }
}
