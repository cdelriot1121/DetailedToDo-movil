import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../../../app/theme.dart';
import '../../../core/widgets/app_card.dart';

/// Panel de personalización: el usuario elige entre el tema claro original y
/// tres temas oscuros de distinto color.
///
/// Cada opción muestra una previsualización en miniatura pintada con la paleta
/// real de ese tema, y el cambio se aplica al instante en toda la app.
class CustomizationScreen extends ConsumerWidget {
  const CustomizationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedTheme = ref.watch(appThemeProvider);
    final palette = context.palette;

    return Scaffold(
      backgroundColor: palette.scaffoldBackground,
      appBar: AppBar(title: const Text('Personalización')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          children: [
            Text(
              'Tema de la aplicación',
              style: TextStyle(
                color: palette.primaryText,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Elige cómo se ve DetailedToDo. El cambio se aplica al instante.',
              style: TextStyle(
                color: palette.secondaryText,
                fontSize: 13,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 16),

            for (final themeId in AppThemeId.values) ...[
              _ThemeOptionCard(
                themeId: themeId,
                isSelected: themeId == selectedTheme,
                onTap: () =>
                    ref.read(appThemeProvider.notifier).select(themeId),
              ),
              const SizedBox(height: 12),
            ],

            const SizedBox(height: 12),
            AppCard(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    PhosphorIconsRegular.fadersHorizontal,
                    size: 18,
                    color: palette.secondaryText,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Tu elección se guarda en este dispositivo. Cuando '
                      'conectemos tu cuenta, se sincronizará automáticamente.',
                      style: TextStyle(
                        color: palette.secondaryText,
                        fontSize: 13,
                        height: 1.35,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ThemeOptionCard extends StatelessWidget {
  const _ThemeOptionCard({
    required this.themeId,
    required this.isSelected,
    required this.onTap,
  });

  final AppThemeId themeId;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    // Paleta activa: se usa para el marco de la tarjeta.
    final palette = context.palette;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: palette.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? palette.accent : palette.border,
            width: isSelected ? 1.6 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(
                  themeId.isDark
                      ? Icons.dark_mode_outlined
                      : Icons.light_mode_outlined,
                  size: 18,
                  color: isSelected ? palette.accent : palette.secondaryText,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        themeId.label,
                        style: TextStyle(
                          color: palette.primaryText,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        themeId.description,
                        style: TextStyle(
                          color: palette.secondaryText,
                          fontSize: 12.5,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  isSelected
                      ? PhosphorIconsFill.checkCircle
                      : PhosphorIconsRegular.circle,
                  size: 22,
                  color: isSelected ? palette.accent : palette.placeholder,
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Previsualización con la paleta del tema que representa.
            _ThemePreview(palette: themeId.palette),
          ],
        ),
      ),
    );
  }
}

/// Miniatura de la interfaz pintada con una paleta concreta.
class _ThemePreview extends StatelessWidget {
  const _ThemePreview({required this.palette});

  final AppPalette palette;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: palette.scaffoldBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: palette.border),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              _bar(width: 54, height: 8, color: palette.primaryText),
              const Spacer(),
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: palette.accent,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: palette.surface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: palette.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: palette.accent, width: 2),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _bar(
                        width: double.infinity,
                        height: 7,
                        color: palette.primaryText,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Padding(
                  padding: const EdgeInsets.only(left: 22),
                  child: _bar(
                    width: 70,
                    height: 6,
                    color: palette.secondaryText,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Container(
                width: 58,
                height: 14,
                decoration: BoxDecoration(
                  color: palette.surfaceSecondary,
                  borderRadius: BorderRadius.circular(7),
                ),
              ),
              const SizedBox(width: 6),
              Container(
                width: 40,
                height: 14,
                decoration: BoxDecoration(
                  color: palette.accent,
                  borderRadius: BorderRadius.circular(7),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _bar({
    required double width,
    required double height,
    required Color color,
  }) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(height / 2),
      ),
    );
  }
}
