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
        child: Image.asset(
          'assets/DetailedToDoLogo_v1.png',
          width: 170,
          height: 170,
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}
