import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_text_field.dart';
import '../viewmodels/auth_view_model.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _otpFormKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _otpController = TextEditingController();

  bool _waitingForOtp = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _submitRegister() async {
    if (!_formKey.currentState!.validate()) return;

    final success = await ref.read(authViewModelProvider.notifier).register(
          _nameController.text,
          _emailController.text,
          _passwordController.text,
        );

    if (success && mounted) {
      setState(() {
        _waitingForOtp = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Código de verificación enviado a tu correo.'),
          backgroundColor: AppColors.primarySurface,
        ),
      );
    }
  }

  Future<void> _submitOtp() async {
    if (!_otpFormKey.currentState!.validate()) return;

    final success = await ref.read(authViewModelProvider.notifier).verifyOtp(
          _emailController.text,
          _otpController.text,
        );

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('¡Cuenta verificada y creada con éxito!'),
          backgroundColor: AppColors.primarySurface,
        ),
      );
      context.go('/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authViewModelProvider);

    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: AppBar(
        title: Text(_waitingForOtp ? 'Verificar correo' : 'Crear cuenta'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: _waitingForOtp
              ? Form(
                  key: _otpFormKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        'Introduce el código OTP',
                        style: TextStyle(
                          color: AppColors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Hemos enviado un código de 6 dígitos a ${_emailController.text.trim()}. Expira en 5 minutos.',
                        style: const TextStyle(
                          color: AppColors.secondaryText,
                          fontSize: 14,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 24),

                      if (authState.errorMessage != null) ...[
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.error.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: AppColors.error.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Text(
                            authState.errorMessage!,
                            style: const TextStyle(
                              color: AppColors.error,
                              fontSize: 13,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],

                      AppTextField(
                        label: 'Código de 6 dígitos',
                        controller: _otpController,
                        keyboardType: TextInputType.number,
                        autofocus: true,
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return 'Ingresa el código OTP';
                          }
                          if (v.trim().length != 6) {
                            return 'El código debe tener 6 dígitos';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 28),

                      AppButton(
                        label: 'Verificar y entrar',
                        isLoading: authState.isLoading,
                        onPressed: _submitOtp,
                        variant: AppButtonVariant.primary,
                      ),
                      const SizedBox(height: 16),

                      TextButton(
                        onPressed: () {
                          setState(() {
                            _waitingForOtp = false;
                          });
                        },
                        child: const Text(
                          'Volver a editar mis datos',
                          style: TextStyle(
                            color: AppColors.secondaryText,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              : Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        'Comienza con DetailedToDo',
                        style: TextStyle(
                          color: AppColors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Crea una cuenta para organizar tus notas, tareas y eventos con IA.',
                        style: TextStyle(
                          color: AppColors.secondaryText,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 24),

                      if (authState.errorMessage != null) ...[
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.error.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: AppColors.error.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Text(
                            authState.errorMessage!,
                            style: const TextStyle(
                              color: AppColors.error,
                              fontSize: 13,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Name
                      AppTextField(
                        label: 'Nombre completo',
                        controller: _nameController,
                        validator: (v) => Validators.requiredField(v, 'El nombre'),
                      ),
                      const SizedBox(height: 16),

                      // Email
                      AppTextField(
                        label: 'Correo electrónico',
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        validator: Validators.email,
                      ),
                      const SizedBox(height: 16),

                      // Password
                      AppTextField(
                        label: 'Contraseña',
                        controller: _passwordController,
                        isPassword: true,
                        validator: Validators.password,
                      ),
                      const SizedBox(height: 16),

                      // Confirm Password
                      AppTextField(
                        label: 'Confirmar contraseña',
                        controller: _confirmPasswordController,
                        isPassword: true,
                        validator: (v) =>
                            Validators.confirmPassword(v, _passwordController.text),
                      ),
                      const SizedBox(height: 28),

                      // Submit Button
                      AppButton(
                        label: 'Solicitar código de verificación',
                        isLoading: authState.isLoading,
                        onPressed: _submitRegister,
                        variant: AppButtonVariant.primary,
                      ),
                      const SizedBox(height: 20),

                      // Back to login
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            '¿Ya tienes una cuenta? ',
                            style: TextStyle(
                              color: AppColors.secondaryText,
                              fontSize: 14,
                            ),
                          ),
                          GestureDetector(
                            onTap: () => context.pop(),
                            child: const Text(
                              'Iniciar sesión',
                              style: TextStyle(
                                color: AppColors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
        ),
      ),
    );
  }
}
