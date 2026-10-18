import 'package:flutter/material.dart';

Widget buildGoogleSignInButton({
  required bool isDark,
  required VoidCallback onPressed,
}) =>
    ElevatedButton.icon(
      onPressed: onPressed,
      icon: const Icon(Icons.g_mobiledata),
      label: const Text('Continuar con Google'),
    );
