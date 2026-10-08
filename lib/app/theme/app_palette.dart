import 'package:flutter/material.dart';

/// Colores que **no** cambian entre temas (acentos semánticos).
///
/// Todo lo demás (fondos, superficies, textos, bordes, acento principal)
/// vive en [AppPalette] y se lee a través de `context.palette`.
class AppColors {
  AppColors._();

  // Neutros absolutos
  static const Color pureWhite = Color(0xFFFFFFFF);
  static const Color pureBlack = Color(0xFF000000);

  // Estados
  static const Color error = Color(0xFFE57373);
  static const Color success = Color(0xFF81C784);

  // Prioridades
  static const Color highPriority = Color(0xFFE57373);
  static const Color mediumPriority = Color(0xFFFFB74D);
  static const Color lowPriority = Color(0xFF81C784);
}

/// Paleta semántica de un tema. Se registra como `ThemeExtension`, por lo que
/// se obtiene con `context.palette` y se interpola al cambiar de tema.
@immutable
class AppPalette extends ThemeExtension<AppPalette> {
  const AppPalette({
    required this.scaffoldBackground,
    required this.surface,
    required this.surfaceSecondary,
    required this.border,
    required this.divider,
    required this.primaryText,
    required this.secondaryText,
    required this.placeholder,
    required this.inputBackground,
    required this.accent,
    required this.onAccent,
    required this.accentContainer,
    required this.onAccentContainer,
    required this.onAccentContainerMuted,
    required this.decoration1,
    required this.decoration2,
    required this.warningContainer,
    required this.onWarningContainer,
    required this.track,
    required this.isDark,
  });

  /// Fondo general de la app (`Scaffold`).
  final Color scaffoldBackground;

  /// Superficie principal: tarjetas, diálogos, hojas inferiores.
  final Color surface;

  /// Superficie secundaria: chips, contenedores internos, skeletons.
  final Color surfaceSecondary;

  /// Bordes de tarjetas, campos e inputs.
  final Color border;

  /// Separadores.
  final Color divider;

  /// Texto principal.
  final Color primaryText;

  /// Texto secundario / descripciones.
  final Color secondaryText;

  /// Placeholder, texto deshabilitado.
  final Color placeholder;

  /// Fondo de campos de texto.
  final Color inputBackground;

  /// Color de acento: botones primarios, FAB, elementos activos.
  final Color accent;

  /// Texto/iconos sobre [accent].
  final Color onAccent;

  /// Fondo de tarjetas destacadas con el acento (ej. cuota de IA).
  final Color accentContainer;

  /// Texto principal sobre [accentContainer].
  final Color onAccentContainer;

  /// Texto secundario sobre [accentContainer].
  final Color onAccentContainerMuted;

  /// Fondos decorativos suaves.
  final Color decoration1;
  final Color decoration2;

  /// Avisos (banners de información/advertencia).
  final Color warningContainer;
  final Color onWarningContainer;

  /// Riel de progreso / líneas sutiles.
  final Color track;

  /// `true` si el tema es oscuro.
  final bool isDark;

  @override
  AppPalette copyWith({
    Color? scaffoldBackground,
    Color? surface,
    Color? surfaceSecondary,
    Color? border,
    Color? divider,
    Color? primaryText,
    Color? secondaryText,
    Color? placeholder,
    Color? inputBackground,
    Color? accent,
    Color? onAccent,
    Color? accentContainer,
    Color? onAccentContainer,
    Color? onAccentContainerMuted,
    Color? decoration1,
    Color? decoration2,
    Color? warningContainer,
    Color? onWarningContainer,
    Color? track,
    bool? isDark,
  }) {
    return AppPalette(
      scaffoldBackground: scaffoldBackground ?? this.scaffoldBackground,
      surface: surface ?? this.surface,
      surfaceSecondary: surfaceSecondary ?? this.surfaceSecondary,
      border: border ?? this.border,
      divider: divider ?? this.divider,
      primaryText: primaryText ?? this.primaryText,
      secondaryText: secondaryText ?? this.secondaryText,
      placeholder: placeholder ?? this.placeholder,
      inputBackground: inputBackground ?? this.inputBackground,
      accent: accent ?? this.accent,
      onAccent: onAccent ?? this.onAccent,
      accentContainer: accentContainer ?? this.accentContainer,
      onAccentContainer: onAccentContainer ?? this.onAccentContainer,
      onAccentContainerMuted:
          onAccentContainerMuted ?? this.onAccentContainerMuted,
      decoration1: decoration1 ?? this.decoration1,
      decoration2: decoration2 ?? this.decoration2,
      warningContainer: warningContainer ?? this.warningContainer,
      onWarningContainer: onWarningContainer ?? this.onWarningContainer,
      track: track ?? this.track,
      isDark: isDark ?? this.isDark,
    );
  }

  @override
  AppPalette lerp(covariant ThemeExtension<AppPalette>? other, double t) {
    if (other is! AppPalette) return this;
    return AppPalette(
      scaffoldBackground:
          Color.lerp(scaffoldBackground, other.scaffoldBackground, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surfaceSecondary:
          Color.lerp(surfaceSecondary, other.surfaceSecondary, t)!,
      border: Color.lerp(border, other.border, t)!,
      divider: Color.lerp(divider, other.divider, t)!,
      primaryText: Color.lerp(primaryText, other.primaryText, t)!,
      secondaryText: Color.lerp(secondaryText, other.secondaryText, t)!,
      placeholder: Color.lerp(placeholder, other.placeholder, t)!,
      inputBackground: Color.lerp(inputBackground, other.inputBackground, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      onAccent: Color.lerp(onAccent, other.onAccent, t)!,
      accentContainer: Color.lerp(accentContainer, other.accentContainer, t)!,
      onAccentContainer:
          Color.lerp(onAccentContainer, other.onAccentContainer, t)!,
      onAccentContainerMuted:
          Color.lerp(onAccentContainerMuted, other.onAccentContainerMuted, t)!,
      decoration1: Color.lerp(decoration1, other.decoration1, t)!,
      decoration2: Color.lerp(decoration2, other.decoration2, t)!,
      warningContainer:
          Color.lerp(warningContainer, other.warningContainer, t)!,
      onWarningContainer:
          Color.lerp(onWarningContainer, other.onWarningContainer, t)!,
      track: Color.lerp(track, other.track, t)!,
      isDark: t < 0.5 ? isDark : other.isDark,
    );
  }
}

/// Catálogo de paletas disponibles.
class AppPalettes {
  AppPalettes._();

  /// Tema claro original (diseño de Penpot).
  static const AppPalette claro = AppPalette(
    scaffoldBackground: Color(0xFFFAFAFA),
    surface: Color(0xFFFFFFFF),
    surfaceSecondary: Color(0xFFF0F0F0),
    border: Color(0xFFE2E2E2),
    divider: Color(0xFFE2E2E2),
    primaryText: Color(0xFF111111),
    secondaryText: Color(0xFF666666),
    placeholder: Color(0xFF999999),
    inputBackground: Color(0xFFFFFFFF),
    accent: Color(0xFF111111),
    onAccent: Color(0xFFFFFFFF),
    accentContainer: Color(0xFF111111),
    onAccentContainer: Color(0xFFFFFFFF),
    onAccentContainerMuted: Color(0xFFCCCCCC),
    decoration1: Color(0xFFF0F0F0),
    decoration2: Color(0xFFEBEBEB),
    warningContainer: Color(0xFFFFF4E5),
    onWarningContainer: Color(0xFF8A5200),
    track: Color(0xFF444444),
    isDark: false,
  );

  /// Oscuro neutro: grises/negros con acento claro.
  static const AppPalette grafito = AppPalette(
    scaffoldBackground: Color(0xFF0F0F11),
    surface: Color(0xFF1A1A1E),
    surfaceSecondary: Color(0xFF232329),
    border: Color(0xFF2E2E36),
    divider: Color(0xFF2A2A31),
    primaryText: Color(0xFFF4F4F6),
    secondaryText: Color(0xFFA6A6B0),
    placeholder: Color(0xFF6F6F7A),
    inputBackground: Color(0xFF1A1A1E),
    accent: Color(0xFFEDEDF2),
    onAccent: Color(0xFF121216),
    accentContainer: Color(0xFF202027),
    onAccentContainer: Color(0xFFF4F4F6),
    onAccentContainerMuted: Color(0xFFA6A6B0),
    decoration1: Color(0xFF1D1D22),
    decoration2: Color(0xFF26262D),
    warningContainer: Color(0xFF3A2B14),
    onWarningContainer: Color(0xFFFFCF87),
    track: Color(0xFF3A3A43),
    isDark: true,
  );

  /// Oscuro azul: azules profundos con acento celeste.
  static const AppPalette oceano = AppPalette(
    scaffoldBackground: Color(0xFF0A1120),
    surface: Color(0xFF111B2E),
    surfaceSecondary: Color(0xFF17253C),
    border: Color(0xFF22344F),
    divider: Color(0xFF1E2E47),
    primaryText: Color(0xFFE8F1FF),
    secondaryText: Color(0xFF9DB2CE),
    placeholder: Color(0xFF6C82A2),
    inputBackground: Color(0xFF111B2E),
    accent: Color(0xFF62A8FF),
    onAccent: Color(0xFF08111F),
    accentContainer: Color(0xFF16243C),
    onAccentContainer: Color(0xFFE8F1FF),
    onAccentContainerMuted: Color(0xFF9DB2CE),
    decoration1: Color(0xFF131F34),
    decoration2: Color(0xFF1A2941),
    warningContainer: Color(0xFF3A2C12),
    onWarningContainer: Color(0xFFFFD08A),
    track: Color(0xFF24354F),
    isDark: true,
  );

  /// Oscuro violeta: morados profundos con acento lila.
  static const AppPalette amatista = AppPalette(
    scaffoldBackground: Color(0xFF100C1A),
    surface: Color(0xFF1A1426),
    surfaceSecondary: Color(0xFF231B33),
    border: Color(0xFF33274A),
    divider: Color(0xFF2C2140),
    primaryText: Color(0xFFF1EAFF),
    secondaryText: Color(0xFFB0A3C9),
    placeholder: Color(0xFF7C6E96),
    inputBackground: Color(0xFF1A1426),
    accent: Color(0xFFC08CFF),
    onAccent: Color(0xFF150E22),
    accentContainer: Color(0xFF211832),
    onAccentContainer: Color(0xFFF1EAFF),
    onAccentContainerMuted: Color(0xFFB0A3C9),
    decoration1: Color(0xFF1C1529),
    decoration2: Color(0xFF241C36),
    warningContainer: Color(0xFF3A2A14),
    onWarningContainer: Color(0xFFFFD08A),
    track: Color(0xFF362A4E),
    isDark: true,
  );
}

/// Identificador de cada tema disponible en la app.
///
/// El `id` es el valor que se persiste, así que no debe cambiarse sin migrar
/// las preferencias guardadas.
enum AppThemeId {
  claro(
    id: 'claro',
    label: 'Claro',
    description: 'El tema original, limpio y minimalista.',
    brightness: Brightness.light,
    palette: AppPalettes.claro,
  ),
  grafito(
    id: 'grafito',
    label: 'Oscuro Grafito',
    description: 'Negros neutros con acentos claros.',
    brightness: Brightness.dark,
    palette: AppPalettes.grafito,
  ),
  oceano(
    id: 'oceano',
    label: 'Oscuro Océano',
    description: 'Azules profundos con acento celeste.',
    brightness: Brightness.dark,
    palette: AppPalettes.oceano,
  ),
  amatista(
    id: 'amatista',
    label: 'Oscuro Amatista',
    description: 'Violetas con acento lila.',
    brightness: Brightness.dark,
    palette: AppPalettes.amatista,
  );

  const AppThemeId({
    required this.id,
    required this.label,
    required this.description,
    required this.brightness,
    required this.palette,
  });

  /// Clave usada para persistir la preferencia.
  final String id;

  /// Nombre visible en el panel de personalización.
  final String label;

  /// Descripción corta del tema.
  final String description;

  /// Brillo del tema.
  final Brightness brightness;

  /// Paleta asociada.
  final AppPalette palette;

  /// `true` si el tema es oscuro.
  bool get isDark => brightness == Brightness.dark;

  /// Devuelve el tema con ese `id`, o el tema claro si no existe.
  static AppThemeId fromId(String? id) {
    for (final theme in AppThemeId.values) {
      if (theme.id == id) return theme;
    }
    return AppThemeId.claro;
  }
}

/// Acceso directo a la paleta activa desde cualquier `BuildContext`:
/// `color: context.palette.primaryText`.
extension AppPaletteContext on BuildContext {
  AppPalette get palette {
    final theme = Theme.of(this);
    return theme.extension<AppPalette>() ??
        (theme.brightness == Brightness.dark
            ? AppPalettes.grafito
            : AppPalettes.claro);
  }
}
