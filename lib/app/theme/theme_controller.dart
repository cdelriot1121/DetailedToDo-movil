import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/storage/secure_storage_service.dart';
import 'app_palette.dart';

/// Contrato de persistencia de las preferencias visuales del usuario.
///
/// Hoy se guardan en el dispositivo; cuando exista la sincronización con la
/// cuenta (MongoDB) bastará con implementar esta interfaz y sustituir el
/// provider, sin tocar la UI.
abstract interface class ThemePreferencesStore {
  Future<String?> readThemeId();

  Future<void> writeThemeId(String themeId);
}

/// Implementación local usando el almacenamiento seguro ya existente.
class LocalThemePreferencesStore implements ThemePreferencesStore {
  const LocalThemePreferencesStore(this._storage);

  final SecureStorageService _storage;

  @override
  Future<String?> readThemeId() => _storage.getThemeId();

  @override
  Future<void> writeThemeId(String themeId) => _storage.saveThemeId(themeId);
}

final themePreferencesStoreProvider = Provider<ThemePreferencesStore>((ref) {
  return LocalThemePreferencesStore(ref.watch(secureStorageServiceProvider));
});

/// Tema con el que arranca la app.
///
/// `main.dart` lo sobreescribe con el tema guardado en el dispositivo, para
/// que el primer frame ya use la preferencia del usuario (sin destellos).
final initialAppThemeProvider = Provider<AppThemeId>((ref) => AppThemeId.claro);

/// Tema activo de la app. Al cambiarlo, toda la interfaz se reconstruye.
final appThemeProvider = NotifierProvider<AppThemeController, AppThemeId>(
  AppThemeController.new,
);

class AppThemeController extends Notifier<AppThemeId> {
  ThemePreferencesStore get _store => ref.read(themePreferencesStoreProvider);

  @override
  AppThemeId build() {
    // Restaura la preferencia guardada sin bloquear el primer frame.
    Future.microtask(_restore);
    return ref.read(initialAppThemeProvider);
  }

  Future<void> _restore() async {
    try {
      final storedId = await _store.readThemeId();
      final stored = AppThemeId.fromId(storedId);
      if (storedId != null && stored != state) {
        state = stored;
      }
    } catch (_) {
      // Si falla la lectura, se mantiene el tema por defecto.
    }
  }

  /// Aplica el tema y lo guarda para la próxima sesión.
  Future<void> select(AppThemeId theme) async {
    if (state == theme) return;
    state = theme;
    try {
      await _store.writeThemeId(theme.id);
    } catch (_) {
      // La preferencia se aplica igual aunque no se pueda persistir.
    }
  }
}
