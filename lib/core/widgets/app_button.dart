import 'package:flutter/material.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import '../../app/theme.dart';

enum AppButtonVariant { primary, secondary, outline, danger, ai }

class AppButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final AppButtonVariant variant;
  final IconData? icon;
  final double? width;
  final double height;

  const AppButton({
    super.key,
    required this.label,
    this.onPressed,
    this.isLoading = false,
    this.variant = AppButtonVariant.primary,
    this.icon,
    this.width,
    this.height = 48,
  });

  @override
  Widget build(BuildContext context) {
    Color backgroundColor;
    Color foregroundColor;
    BorderSide borderSide = BorderSide.none;

    switch (variant) {
      case AppButtonVariant.primary:
        backgroundColor = context.palette.accent;
        foregroundColor = context.palette.onAccent;
        break;
      case AppButtonVariant.secondary:
        backgroundColor = context.palette.surfaceSecondary;
        foregroundColor = context.palette.primaryText;
        borderSide = BorderSide(color: context.palette.border, width: 1);
        break;
      case AppButtonVariant.outline:
        backgroundColor = Colors.transparent;
        foregroundColor = context.palette.primaryText;
        borderSide = BorderSide(color: context.palette.border, width: 1);
        break;
      case AppButtonVariant.danger:
        backgroundColor = AppColors.error.withValues(alpha: 0.15);
        foregroundColor = AppColors.error;
        borderSide = BorderSide(
          color: AppColors.error.withValues(alpha: 0.3),
          width: 1,
        );
        break;
      case AppButtonVariant.ai:
        backgroundColor = context.palette.accent;
        foregroundColor = context.palette.onAccent;
        break;
    }

    final isClickable = onPressed != null && !isLoading;

    return SizedBox(
      width: width,
      height: height,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: isClickable
              ? backgroundColor
              : context.palette.surfaceSecondary,
          foregroundColor: isClickable
              ? foregroundColor
              : context.palette.placeholder,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: isClickable
                ? borderSide
                : BorderSide(color: context.palette.border),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16),
        ),
        onPressed: isClickable ? onPressed : null,
        child: isLoading
            ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    variant == AppButtonVariant.primary ||
                            variant == AppButtonVariant.ai
                        ? context.palette.onAccent
                        : context.palette.accent,
                  ),
                ),
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (variant == AppButtonVariant.ai) ...[
                    const Icon(PhosphorIconsRegular.sparkle, size: 18),
                    const SizedBox(width: 8),
                  ] else if (icon != null) ...[
                    Icon(icon, size: 18),
                    const SizedBox(width: 8),
                  ],
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.2,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
