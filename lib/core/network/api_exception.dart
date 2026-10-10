import 'package:dio/dio.dart';
import '../../shared/models/api_error.dart';

class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final ApiError? apiError;
  final dynamic originalError;

  const ApiException({
    required this.message,
    this.statusCode,
    this.apiError,
    this.originalError,
  });

  factory ApiException.fromDioError(DioException dioException) {
    int? status = dioException.response?.statusCode;
    ApiError? apiError;
    String userMessage = 'Ocurrió un error inesperado. Inténtalo de nuevo.';

    if (dioException.response?.data is Map<String, dynamic>) {
      try {
        apiError = ApiError.fromJson(
          dioException.response!.data as Map<String, dynamic>,
        );
      } catch (_) {}
    }

    switch (dioException.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        userMessage = 'El tiempo de espera se ha agotado. Verifica tu conexión.';
        break;
      case DioExceptionType.connectionError:
        userMessage = 'No se pudo conectar con el servidor. Revisa tu conexión de red.';
        break;
      case DioExceptionType.badResponse:
        if (status == 400) {
          userMessage = apiError?.message ?? 'Los datos ingresados no son válidos.';
        } else if (status == 401) {
          userMessage = 'Tu sesión ha expirado o las credenciales son incorrectas.';
        } else if (status == 403) {
          userMessage = 'No tienes permiso para realizar esta acción.';
        } else if (status == 404) {
          userMessage = apiError?.message ?? 'El recurso solicitado no fue encontrado.';
        } else if (status == 409) {
          userMessage = apiError?.message ?? 'Ese dato o correo ya se encuentra registrado.';
        } else if (status == 429) {
          userMessage = apiError?.message ?? 'Espera un minuto antes de solicitar otro código.';
        } else if (status != null && status >= 500) {
          userMessage = 'No pudimos completar la operación en el servidor. Inténtalo nuevamente.';
        } else {
          userMessage = apiError?.message ?? 'Error en la respuesta del servidor ($status).';
        }
        break;
      case DioExceptionType.cancel:
        userMessage = 'La petición fue cancelada.';
        break;
      default:
        userMessage = apiError?.message ?? 'Error de comunicación con el servicio.';
    }

    return ApiException(
      message: userMessage,
      statusCode: status,
      apiError: apiError,
      originalError: dioException,
    );
  }

  bool get isNetworkError {
    if (statusCode == null) return true;
    if (originalError is DioException) {
      final type = (originalError as DioException).type;
      return type == DioExceptionType.connectionError ||
          type == DioExceptionType.connectionTimeout ||
          type == DioExceptionType.sendTimeout ||
          type == DioExceptionType.receiveTimeout;
    }
    return false;
  }

  @override
  String toString() => message;
}
