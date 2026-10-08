import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'router.dart';
import 'theme.dart';

class DetailedToDoApp extends ConsumerWidget {
  const DetailedToDoApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final themeId = ref.watch(appThemeProvider);
    final themeData = AppTheme.build(themeId);

    return MaterialApp.router(
      title: 'DetailedToDo',
      debugShowCheckedModeBanner: false,
      // Un único ThemeData por tema: se asigna a `theme` y `darkTheme`, y el
      // ThemeMode acompaña al brillo de la paleta elegida.
      theme: themeData,
      darkTheme: themeData,
      themeMode: themeId.isDark ? ThemeMode.dark : ThemeMode.light,
      themeAnimationDuration: const Duration(milliseconds: 300),
      themeAnimationCurve: Curves.easeInOut,
      routerConfig: router,
    );
  }
}
