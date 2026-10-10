import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'app/app.dart';
import 'app/theme.dart';
import 'core/notifications/notification_service.dart';
import 'core/storage/local_storage_service.dart';
import 'core/storage/secure_storage_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Spanish date formatting for intl
  await initializeDateFormatting('es', null);

  // Initialize local storage (Hive: Web IndexedDB / Mobile disk)
  await LocalStorageService.init();

  // Initialize notification service gracefully
  final notificationService = NotificationService();
  await notificationService.init();

  final secureStorage = SecureStorageService(const FlutterSecureStorage());

  // Tema guardado: se resuelve antes del primer frame para que la app arranque
  // directamente con la preferencia del usuario.
  AppThemeId savedTheme = AppThemeId.claro;
  try {
    savedTheme = AppThemeId.fromId(await secureStorage.getThemeId());
  } catch (_) {
    // Si falla la lectura se usa el tema claro.
  }

  runApp(
    ProviderScope(
      overrides: [
        notificationServiceProvider.overrideWithValue(notificationService),
        secureStorageServiceProvider.overrideWithValue(secureStorage),
        initialAppThemeProvider.overrideWithValue(savedTheme),
      ],
      child: const DetailedToDoApp(),
    ),
  );
}
