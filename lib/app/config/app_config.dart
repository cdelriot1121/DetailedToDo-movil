import 'package:flutter/foundation.dart';

class AppConfig {
  static const String _envUrl = String.fromEnvironment('API_BASE_URL');

  static String get apiBaseUrl {
    String base;
    if (_envUrl.isNotEmpty) {
      base = _envUrl;
    } else if (kIsWeb) {
      base = 'https://detailedtodo-backend.up.railway.app/api';  //http://localhost:8000/api
    } else {
      base = 'http://192.168.1.21:8000/api';
    }

    if (!base.endsWith('/')) {
      base = '$base/';
    }
    return base;
  }

  static const Duration connectTimeout = Duration(seconds: 15);
  static const Duration receiveTimeout = Duration(seconds: 15);
}
