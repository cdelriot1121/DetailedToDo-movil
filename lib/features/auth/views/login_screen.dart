import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'dart:async';
import '../../../app/theme.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/app_text_field.dart';
import 'google_g_mark.dart';
import '../viewmodels/auth_view_model.dart';
import 'google_sign_in_button_stub.dart'
    if (dart.library.html) 'google_sign_in_button_web.dart' as google_button;

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  StreamSubscription<GoogleSignInAuthenticationEvent>? _googleEvents;
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (kIsWeb) {
      _googleEvents = GoogleSignIn.instance.authenticationEvents.listen((event) {
        if (event is GoogleSignInAuthenticationEventSignIn) {
          final idToken = event.user.authentication.idToken;
          if (idToken != null) _completeGoogleSignIn(idToken);
        }
      });
    }
  }

  Future<void> _signInWithGoogle() async {
    if (kIsWeb) return; // En web el botón oficial de GIS inicia el flujo.
    try {
      final account = await GoogleSignIn.instance.authenticate();
      final idToken = account.authentication.idToken;
      if (idToken == null) throw StateError('Google no devolvió un ID token.');
      await _completeGoogleSignIn(idToken);
    } catch (_) {
      if (mounted) {
        ref.read(authViewModelProvider.notifier).clearError();
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No se pudo iniciar sesión con Google.')));
      }
    }
  }

  Future<void> _completeGoogleSignIn(String idToken) async {
    final success = await ref.read(authViewModelProvider.notifier).loginWithGoogle(idToken);
    if (success && mounted) context.go('/home');
  }

  @override
  void dispose() {
    _googleEvents?.cancel();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final success = await ref.read(authViewModelProvider.notifier).login(
          _emailController.text,
          _passwordController.text,
        );

    if (success && mounted) {
      context.go('/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authViewModelProvider);

    return Scaffold(
      backgroundColor: context.palette.scaffoldBackground,
      body: Stack(
        children: [
          // Decoraciones de fondo (circulos sutiles del prototipo)
          Positioned(
            left: -60,
            top: -90,
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                color: context.palette.decoration1,
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            right: -30,
            top: 60,
            child: Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                color: context.palette.decoration2,
                shape: BoxShape.circle,
              ),
            ),
          ),

          // Contenido principal
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Logo
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: context.palette.accent,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Icon(
                        Icons.check_rounded,
                        color: context.palette.onAccent,
                        size: 32,
                      ),
                    ),
                    const SizedBox(height: 56),

                    // Titulo
                    Text(
                      'Bienvenido de vuelta',
                      style: TextStyle(
                        color: context.palette.primaryText,
                        fontSize: 30,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.6,
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Subtitulo
                    Text(
                      'Organiza tu dia con DetailedToDo y deja que la IA te ayude a priorizar.',
                      style: TextStyle(
                        color: context.palette.secondaryText,
                        fontSize: 15,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 40),

                    // Banner de error
                    if (authState.errorMessage != null) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.error.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: AppColors.error.withValues(alpha: 0.25),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.error_outline_rounded,
                              color: AppColors.error,
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                authState.errorMessage!,
                                style: const TextStyle(
                                  color: AppColors.error,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],

                    // Campo: Correo electronico
                    Text(
                      'Correo electronico',
                      style: TextStyle(
                        color: context.palette.secondaryText,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    AppTextField(
                      hint: 'tu@correo.com',
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      validator: Validators.email,
                      prefixIcon: Icon(
                        Icons.mail_outline_rounded,
                        color: context.palette.placeholder,
                        size: 20,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Campo: Contrasena
                    Text(
                      'Contrasena',
                      style: TextStyle(
                        color: context.palette.secondaryText,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    AppTextField(
                      hint: 'Tu contrasena',
                      controller: _passwordController,
                      isPassword: true,
                      validator: Validators.password,
                      prefixIcon: Icon(
                        Icons.lock_outline_rounded,
                        color: context.palette.placeholder,
                        size: 20,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Olvide contrasena
                    Align(
                      alignment: Alignment.centerRight,
                      child: GestureDetector(
                      onTap: () => context.push('/forgot-password'),
                        child: Text(
                          'Olvidaste tu contrasena?',
                          style: TextStyle(
                            color: context.palette.primaryText,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),

                    // Boton principal: Iniciar sesion
                    SizedBox(
                      height: 52,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: context.palette.accent,
                          foregroundColor: context.palette.onAccent,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        onPressed: authState.isLoading ? null : _submit,
                        child: authState.isLoading
                            ? SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      context.palette.onAccent),
                                ),
                              )
                            : const Text(
                                'Iniciar sesion',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 28),

                    // Divisor "o"
                    Row(
                      children: [
                        Expanded(
                          child: Divider(
                            color: context.palette.divider,
                            thickness: 1,
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 12),
                          child: Text(
                            'o',
                            style: TextStyle(
                              color: context.palette.secondaryText,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Divider(
                            color: context.palette.divider,
                            thickness: 1,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Boton: Continuar con Google
                    if (kIsWeb)
                      Center(
                        child: google_button.buildGoogleSignInButton(
                          isDark: context.palette.isDark,
                          onPressed: _signInWithGoogle,
                        ),
                      )
                    else
                      Container(
                      height: 64,
                      decoration: BoxDecoration(
                        color: context.palette.surface,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: context.palette.border),
                        boxShadow: [
                          BoxShadow(
                            color: context.palette.accent.withValues(alpha: 0.08),
                            blurRadius: 18,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: context.palette.primaryText,
                          side: BorderSide.none,
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                        ),
                        onPressed: authState.isLoading ? null : _signInWithGoogle,
                        child: Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: context.palette.accentContainer,
                                borderRadius: BorderRadius.circular(13),
                              ),
                              child: const Center(child: GoogleGMark(size: 23)),
                            ),
                            const SizedBox(width: 13),
                            Expanded(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Continuar con Google',
                                    style: TextStyle(
                                      color: context.palette.primaryText,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Acceso rápido y seguro',
                                    style: TextStyle(
                                      color: context.palette.secondaryText,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (authState.isLoading)
                              SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: context.palette.accent,
                                ),
                              )
                            else
                              Icon(
                                Icons.arrow_forward_rounded,
                                size: 19,
                                color: context.palette.secondaryText,
                              ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),

                    // Link: Crear cuenta
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'No tienes cuenta?  ',
                          style: TextStyle(
                            color: context.palette.secondaryText,
                            fontSize: 14,
                          ),
                        ),
                        GestureDetector(
                          onTap: () => context.push('/register'),
                          child: Text(
                            'Registrate',
                            style: TextStyle(
                              color: context.palette.primaryText,
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
