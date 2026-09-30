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
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  final List<TextEditingController> _otpDigitControllers =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _otpFocusNodes =
      List.generate(6, (_) => FocusNode());

  bool _waitingForOtp = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    for (final c in _otpDigitControllers) {
      c.dispose();
    }
    for (final f in _otpFocusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  String _getOtpCode() {
    return _otpDigitControllers.map((c) => c.text.trim()).join();
  }

  Future<void> _submitRegister() async {
    if (!_formKey.currentState!.validate()) return;

    final success = await ref.read(authViewModelProvider.notifier).register(
          _nameController.text,
          _emailController.text,
          _passwordController.text,
        );

    if (success && mounted) {
      for (final c in _otpDigitControllers) {
        c.clear();
      }
      setState(() {
        _waitingForOtp = true;
      });
      Future.delayed(const Duration(milliseconds: 200), () {
        if (mounted && _otpFocusNodes.isNotEmpty) {
          _otpFocusNodes[0].requestFocus();
        }
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
    final code = _getOtpCode();
    if (code.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor completa los 6 dígitos del código OTP.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final success = await ref.read(authViewModelProvider.notifier).verifyOtp(
          _emailController.text,
          code,
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
        title: Text(_waitingForOtp ? 'Verificación OTP' : 'Crear cuenta'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: _waitingForOtp
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 12),
                    Center(
                      child: Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: AppColors.primarySurface,
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.border, width: 1.2),
                        ),
                        child: const Icon(
                          Icons.mark_email_read_outlined,
                          color: AppColors.white,
                          size: 28,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Código de verificación',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppColors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Ingresa el código de 6 dígitos que enviamos a:\n${_emailController.text.trim()}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: AppColors.secondaryText,
                        fontSize: 14,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 28),

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
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: AppColors.error,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],

                    // 6 Separate Pin Digit Boxes
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: List.generate(6, (index) {
                        return SizedBox(
                          width: 46,
                          height: 54,
                          child: TextField(
                            controller: _otpDigitControllers[index],
                            focusNode: _otpFocusNodes[index],
                            keyboardType: TextInputType.number,
                            textAlign: TextAlign.center,
                            maxLength: 1,
                            style: const TextStyle(
                              color: AppColors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                            decoration: InputDecoration(
                              counterText: '',
                              contentPadding: EdgeInsets.zero,
                              filled: true,
                              fillColor: AppColors.inputBackground,
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: const BorderSide(
                                  color: AppColors.border,
                                  width: 1.2,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: const BorderSide(
                                  color: AppColors.white,
                                  width: 1.8,
                                ),
                              ),
                            ),
                            onChanged: (value) {
                              if (value.isNotEmpty) {
                                if (index < 5) {
                                  _otpFocusNodes[index + 1].requestFocus();
                                } else {
                                  _otpFocusNodes[index].unfocus();
                                  _submitOtp();
                                }
                              } else {
                                if (index > 0) {
                                  _otpFocusNodes[index - 1].requestFocus();
                                }
                              }
                            },
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 32),

                    AppButton(
                      label: 'Verificar y entrar',
                      isLoading: authState.isLoading,
                      onPressed: _submitOtp,
                      variant: AppButtonVariant.primary,
                    ),
                    const SizedBox(height: 16),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        TextButton(
                          onPressed: () {
                            setState(() {
                              _waitingForOtp = false;
                            });
                          },
                          child: const Text(
                            'Volver / Cambiar correo',
                            style: TextStyle(
                              color: AppColors.secondaryText,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
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
