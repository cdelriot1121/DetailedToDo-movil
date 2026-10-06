import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme.dart';
import '../../../core/utils/validators.dart';
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

  bool _acceptedTerms = true;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submitRegister() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_acceptedTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Debes aceptar los terminos de uso.'),
          backgroundColor: AppColors.nearBlack,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      return;
    }

    final success = await ref.read(authViewModelProvider.notifier).register(
          _nameController.text,
          _emailController.text,
          _passwordController.text,
        );

    if (success && mounted) {
      context.push('/otp', extra: _emailController.text.trim());
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authViewModelProvider);

    return Scaffold(
      backgroundColor: AppColors.lightScaffold,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Boton atras
                Row(
                  children: [
                    GestureDetector(
                      onTap: () => context.pop(),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: AppColors.lightSurface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.lightBorder),
                        ),
                        child: const Icon(
                          Icons.arrow_back_ios_new_rounded,
                          size: 18,
                          color: AppColors.lightPrimaryText,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 28),

                // Titulo
                const Text(
                  'Crea tu cuenta',
                  style: TextStyle(
                    color: AppColors.lightPrimaryText,
                    fontSize: 30,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.6,
                  ),
                ),
                const SizedBox(height: 10),

                // Subtitulo
                const Text(
                  'Empieza gratis y organiza tareas, notas y eventos en un solo lugar.',
                  style: TextStyle(
                    color: AppColors.lightSecondaryText,
                    fontSize: 15,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 28),

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

                // Campo: Nombre completo
                const Text(
                  'Nombre completo',
                  style: TextStyle(
                    color: AppColors.lightSecondaryText,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                AppTextField(
                  hint: 'Tu nombre',
                  controller: _nameController,
                  validator: (v) => Validators.requiredField(v, 'El nombre'),
                  prefixIcon: const Icon(
                    Icons.person_outline_rounded,
                    color: AppColors.lightPlaceholder,
                    size: 20,
                  ),
                ),
                const SizedBox(height: 18),

                // Campo: Correo electronico
                const Text(
                  'Correo electronico',
                  style: TextStyle(
                    color: AppColors.lightSecondaryText,
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
                  prefixIcon: const Icon(
                    Icons.mail_outline_rounded,
                    color: AppColors.lightPlaceholder,
                    size: 20,
                  ),
                ),
                const SizedBox(height: 18),

                // Campo: Contrasena
                const Text(
                  'Contrasena',
                  style: TextStyle(
                    color: AppColors.lightSecondaryText,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                AppTextField(
                  hint: 'Minimo 8 caracteres',
                  controller: _passwordController,
                  isPassword: true,
                  validator: Validators.password,
                  prefixIcon: const Icon(
                    Icons.lock_outline_rounded,
                    color: AppColors.lightPlaceholder,
                    size: 20,
                  ),
                ),
                const SizedBox(height: 18),

                // Campo: Confirmar contrasena
                const Text(
                  'Confirmar contrasena',
                  style: TextStyle(
                    color: AppColors.lightSecondaryText,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                AppTextField(
                  hint: 'Repite tu contrasena',
                  controller: _confirmPasswordController,
                  isPassword: true,
                  validator: (v) =>
                      Validators.confirmPassword(v, _passwordController.text),
                  prefixIcon: const Icon(
                    Icons.lock_outline_rounded,
                    color: AppColors.lightPlaceholder,
                    size: 20,
                  ),
                ),
                const SizedBox(height: 20),

                // Checkbox: Terminos
                GestureDetector(
                  onTap: () => setState(() => _acceptedTerms = !_acceptedTerms),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        width: 22,
                        height: 22,
                        decoration: BoxDecoration(
                          color: _acceptedTerms
                              ? AppColors.nearBlack
                              : AppColors.lightSurface,
                          borderRadius: BorderRadius.circular(7),
                          border: Border.all(
                            color: _acceptedTerms
                                ? AppColors.nearBlack
                                : AppColors.lightBorder,
                            width: 1.5,
                          ),
                        ),
                        child: _acceptedTerms
                            ? const Icon(
                                Icons.check_rounded,
                                size: 14,
                                color: AppColors.white,
                              )
                            : null,
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'Acepto los terminos de uso y la politica de privacidad',
                          style: TextStyle(
                            color: AppColors.lightSecondaryText,
                            fontSize: 13,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),

                // Boton: Crear cuenta
                SizedBox(
                  height: 52,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.nearBlack,
                      foregroundColor: AppColors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: authState.isLoading ? null : _submitRegister,
                    child: authState.isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                  AppColors.white),
                            ),
                          )
                        : const Text(
                            'Crear cuenta',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 32),

                // Link: Ya tienes cuenta
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'Ya tienes cuenta?  ',
                      style: TextStyle(
                        color: AppColors.lightSecondaryText,
                        fontSize: 14,
                      ),
                    ),
                    GestureDetector(
                      onTap: () => context.pop(),
                      child: const Text(
                        'Inicia sesion',
                        style: TextStyle(
                          color: AppColors.lightPrimaryText,
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
    );
  }
}
