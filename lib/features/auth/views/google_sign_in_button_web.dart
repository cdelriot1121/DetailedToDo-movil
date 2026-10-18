import 'package:flutter/widgets.dart';
import 'package:google_sign_in_web/web_only.dart' as google_web;

Widget buildGoogleSignInButton({
  required bool isDark,
  required VoidCallback onPressed,
}) {
  return LayoutBuilder(
    builder: (context, constraints) {
      final width = constraints.maxWidth.clamp(180.0, 400.0).toDouble();
      return google_web.renderButton(
        configuration: google_web.GSIButtonConfiguration(
          theme: isDark
              ? google_web.GSIButtonTheme.filledBlack
              : google_web.GSIButtonTheme.outline,
          size: google_web.GSIButtonSize.large,
          shape: google_web.GSIButtonShape.pill,
          text: google_web.GSIButtonText.continueWith,
          logoAlignment: google_web.GSIButtonLogoAlignment.left,
          minimumWidth: width,
          locale: 'es',
        ),
      );
    },
  );
}
