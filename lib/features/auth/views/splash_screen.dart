import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme.dart';
import '../viewmodels/auth_view_model.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    await Future.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;
    await ref.read(authViewModelProvider.notifier).checkAuth();
    if (!mounted) return;

    final authState = ref.read(authViewModelProvider);
    if (authState.isAuthenticated) {
      context.go('/home');
    } else {
      context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.palette.scaffoldBackground,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: context.palette.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: context.palette.border, width: 1.5),
              ),
              child: Center(
                child: Text(
                  'D',
                  style: TextStyle(
                    color: context.palette.onAccent,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -1,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'DetailedToDo',
              style: TextStyle(
                color: context.palette.onAccent,
                fontSize: 22,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Organización personal asistida',
              style: TextStyle(
                color: context.palette.secondaryText,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 36),
            SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(context.palette.secondaryText),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
