import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/app_text_field.dart';
import '../viewmodels/auth_view_model.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _code = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _codeRequested = false;

  @override
  void dispose() {
    _email.dispose(); _code.dispose(); _password.dispose(); _confirm.dispose();
    super.dispose();
  }

  Future<void> _requestCode() async {
    final emailError = Validators.email(_email.text);
    if (emailError != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(emailError)));
      return;
    }
    final ok = await ref.read(authViewModelProvider.notifier).requestPasswordReset(_email.text);
    if (ok && mounted) setState(() => _codeRequested = true);
  }

  Future<void> _reset() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final ok = await ref.read(authViewModelProvider.notifier)
        .resetPassword(_email.text, _code.text, _password.text);
    if (ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Contraseña actualizada. Ya puedes iniciar sesión.')),
      );
      context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authViewModelProvider);
    return Scaffold(
      backgroundColor: AppColors.lightScaffold,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Form(
            key: _formKey,
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Align(alignment: Alignment.centerLeft, child: IconButton(
                onPressed: () => context.pop(), icon: const Icon(Icons.arrow_back_ios_new_rounded),
              )),
              const SizedBox(height: 36),
              const Icon(Icons.lock_reset_rounded, size: 64, color: AppColors.nearBlack),
              const SizedBox(height: 24),
              Text(_codeRequested ? 'Crea una nueva contraseña' : '¿Olvidaste tu contraseña?',
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.lightPrimaryText, fontSize: 27, fontWeight: FontWeight.w800)),
              const SizedBox(height: 12),
              Text(_codeRequested
                  ? 'Ingresa el código de 6 dígitos que enviamos a tu correo.'
                  : 'Te enviaremos un código de 6 dígitos al correo de tu cuenta.',
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.lightSecondaryText, fontSize: 15, height: 1.45)),
              const SizedBox(height: 32),
              if (auth.errorMessage != null) ...[
                Text(auth.errorMessage!, style: const TextStyle(color: AppColors.error)),
                const SizedBox(height: 16),
              ],
              AppTextField(hint: 'tu@correo.com', controller: _email,
                keyboardType: TextInputType.emailAddress, validator: Validators.email,
                prefixIcon: const Icon(Icons.mail_outline_rounded)),
              if (_codeRequested) ...[
                const SizedBox(height: 16),
                AppTextField(hint: 'Código de 6 dígitos', controller: _code,
                  keyboardType: TextInputType.number,
                  validator: (v) => (v == null || !RegExp(r'^\d{6}$').hasMatch(v.trim())) ? 'Ingresa los 6 dígitos.' : null,
                  prefixIcon: const Icon(Icons.pin_outlined)),
                const SizedBox(height: 16),
                AppTextField(hint: 'Nueva contraseña', controller: _password,
                  isPassword: true,
                  validator: (v) => (v == null || v.length < 8) ? 'La contraseña debe tener al menos 8 caracteres.' : null,
                  prefixIcon: const Icon(Icons.lock_outline_rounded)),
                const SizedBox(height: 16),
                AppTextField(hint: 'Confirma la contraseña', controller: _confirm,
                  isPassword: true,
                  validator: (v) => v != _password.text ? 'Las contraseñas no coinciden.' : null,
                  prefixIcon: const Icon(Icons.lock_outline_rounded)),
              ],
              const SizedBox(height: 28),
              SizedBox(height: 52, child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.nearBlack, foregroundColor: AppColors.white),
                onPressed: auth.isLoading ? null : (_codeRequested ? _reset : _requestCode),
                child: auth.isLoading
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.white))
                    : Text(_codeRequested ? 'Restablecer contraseña' : 'Enviar código'),
              )),
              if (_codeRequested) ...[
                const SizedBox(height: 16),
                TextButton(onPressed: auth.isLoading ? null : _requestCode, child: const Text('Reenviar código')),
              ],
            ]),
          ),
        ),
      ),
    );
  }
}
