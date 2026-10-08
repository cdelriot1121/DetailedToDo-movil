import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme.dart';
import '../viewmodels/auth_view_model.dart';

class OtpScreen extends ConsumerStatefulWidget {
  final String email;

  const OtpScreen({super.key, required this.email});

  @override
  ConsumerState<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends ConsumerState<OtpScreen> {
  final List<TextEditingController> _controllers =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());

  // Contador de reenvio
  int _resendSeconds = 60;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startTimer();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNodes[0].requestFocus();
    });
  }

  void _startTimer() {
    _timer?.cancel();
    setState(() => _resendSeconds = 60);
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_resendSeconds == 0) {
        t.cancel();
      } else {
        setState(() => _resendSeconds--);
      }
    });
  }

  Future<void> _resend() async {
    final sent = await ref.read(authViewModelProvider.notifier)
        .resendRegistrationOtp(widget.email);
    if (sent && mounted) _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (final c in _controllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  String get _otpCode =>
      _controllers.map((c) => c.text.trim()).join();

  Future<void> _submit() async {
    final code = _otpCode;
    if (code.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Completa los 6 digitos del codigo.'),
          backgroundColor: context.palette.accent,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      return;
    }

    final success = await ref
        .read(authViewModelProvider.notifier)
        .verifyOtp(widget.email, code);

    if (success && mounted) {
      context.go('/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authViewModelProvider);
    final minutes = (_resendSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (_resendSeconds % 60).toString().padLeft(2, '0');

    return Scaffold(
      backgroundColor: context.palette.scaffoldBackground,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Boton atras
              Align(
                alignment: Alignment.centerLeft,
                child: GestureDetector(
                  onTap: () => context.pop(),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: context.palette.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: context.palette.border),
                    ),
                    child: Icon(
                      Icons.arrow_back_ios_new_rounded,
                      size: 18,
                      color: context.palette.primaryText,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // Icono de sobre (email) con halo
              Center(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Halo
                    Container(
                      width: 140,
                      height: 140,
                      decoration: BoxDecoration(
                        color: context.palette.decoration1,
                        shape: BoxShape.circle,
                      ),
                    ),
                    // Sobre
                    Container(
                      width: 80,
                      height: 60,
                      decoration: BoxDecoration(
                        color: context.palette.accent,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(
                        Icons.mark_email_unread_outlined,
                        color: context.palette.onAccent,
                        size: 32,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Titulo
              Text(
                'Verifica tu correo',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: context.palette.primaryText,
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 12),

              // Subtitulo con email
              Text(
                'Enviamos un codigo de 6 digitos a\n${widget.email}',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: context.palette.secondaryText,
                  fontSize: 15,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 36),

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
                const SizedBox(height: 24),
              ],

              // Casillas OTP  (6 digitos, 50x62, borderRadius 14)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(6, (index) {
                  return SizedBox(
                    width: 50,
                    height: 62,
                    child: TextField(
                      controller: _controllers[index],
                      focusNode: _focusNodes[index],
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      maxLength: 1,
                      style: TextStyle(
                        color: context.palette.primaryText,
                        fontSize: 26,
                        fontWeight: FontWeight.w700,
                      ),
                      decoration: InputDecoration(
                        counterText: '',
                        contentPadding: EdgeInsets.zero,
                        filled: true,
                        fillColor: context.palette.surface,
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(
                              color: context.palette.border, width: 1.2),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(
                              color: context.palette.accent, width: 1.8),
                        ),
                      ),
                      onChanged: (value) {
                        if (value.isNotEmpty) {
                          if (index < 5) {
                            _focusNodes[index + 1].requestFocus();
                          } else {
                            _focusNodes[index].unfocus();
                            _submit();
                          }
                        } else {
                          if (index > 0) {
                            _focusNodes[index - 1].requestFocus();
                          }
                        }
                      },
                    ),
                  );
                }),
              ),
              const SizedBox(height: 36),

              // Boton: Verificar codigo
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
                            valueColor:
                                AlwaysStoppedAnimation<Color>(context.palette.onAccent),
                          ),
                        )
                      : const Text(
                          'Verificar codigo',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 24),

              // Reenviar codigo
              Center(
                child: _resendSeconds > 0
                    ? RichText(
                        text: TextSpan(
                          style: TextStyle(
                            fontSize: 14,
                            color: context.palette.secondaryText,
                          ),
                          children: [
                            const TextSpan(text: 'No te llego?  '),
                            TextSpan(
                              text: 'Reenviar codigo en $minutes:$seconds',
                              style: TextStyle(
                                color: context.palette.placeholder,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      )
                    : GestureDetector(
                        onTap: authState.isLoading ? null : _resend,
                        child: RichText(
                          text: TextSpan(
                            style: TextStyle(
                              fontSize: 14,
                              color: context.palette.secondaryText,
                            ),
                            children: [
                              TextSpan(text: 'No te llego?  '),
                              TextSpan(
                                text: 'Reenviar codigo',
                                style: TextStyle(
                                  color: context.palette.primaryText,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
