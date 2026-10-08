/// Sistema de temas de DetailedToDo.
///
/// Punto de entrada único: los widgets importan este archivo y usan
/// `context.palette.<color>` para pintar con el tema activo.
///
/// - [AppPalette] / [AppPalettes]: paletas disponibles (1 clara + 3 oscuras).
/// - [AppThemeId]: temas seleccionables por el usuario.
/// - [AppTheme]: construcción del `ThemeData`.
/// - [appThemeProvider]: tema activo (se cambia desde el panel de
///   personalización del perfil).
library;

export 'theme/app_palette.dart';
export 'theme/app_theme.dart';
export 'theme/theme_controller.dart';
