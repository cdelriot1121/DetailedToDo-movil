import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import '../../../app/theme.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/loading_view.dart';
import '../../auth/viewmodels/auth_view_model.dart';
import '../viewmodels/profile_view_model.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(profileViewModelProvider.notifier).loadProfile();
    });
  }

  void _showEditNameDialog(BuildContext context, String currentName) {
    final controller = TextEditingController(text: currentName);

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: AppColors.primarySurface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: const BorderSide(color: AppColors.border),
          ),
          title: const Text('Editar nombre', style: TextStyle(color: AppColors.white)),
          content: TextField(
            controller: controller,
            autofocus: true,
            style: const TextStyle(color: AppColors.primaryText),
            decoration: const InputDecoration(
              hintText: 'Tu nombre completo',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar', style: TextStyle(color: AppColors.secondaryText)),
            ),
            TextButton(
              onPressed: () async {
                final newName = controller.text.trim();
                if (newName.isNotEmpty) {
                  Navigator.pop(ctx);
                  await ref
                      .read(profileViewModelProvider.notifier)
                      .updateProfile(name: newName);
                }
              },
              child: const Text('Guardar', style: TextStyle(color: AppColors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  void _confirmLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: AppColors.primarySurface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: const BorderSide(color: AppColors.border),
          ),
          title: const Text('¿Cerrar sesión?', style: TextStyle(color: AppColors.white)),
          content: const Text(
            'Tendrás que ingresar tus credenciales nuevamente para acceder.',
            style: TextStyle(color: AppColors.secondaryText),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar', style: TextStyle(color: AppColors.secondaryText)),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(ctx);
                await ref.read(authViewModelProvider.notifier).logout();
                if (context.mounted) {
                  context.go('/login');
                }
              },
              child: const Text('Cerrar sesión', style: TextStyle(color: AppColors.error, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(profileViewModelProvider);

    if (state.isLoading && state.user == null) {
      return const Scaffold(
        backgroundColor: AppColors.scaffoldBackground,
        body: LoadingView(message: 'Cargando perfil...'),
      );
    }

    final user = state.user;
    final quota = state.quota;

    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: AppBar(
        title: const Text('Perfil'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // User Avatar & Info
              Center(
                child: Column(
                  children: [
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        color: AppColors.primarySurface,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.border, width: 1.5),
                      ),
                      child: Center(
                        child: Text(
                          (user?.name.isNotEmpty == true)
                              ? user!.name[0].toUpperCase()
                              : 'U',
                          style: const TextStyle(
                            color: AppColors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      user?.name ?? 'Usuario',
                      style: const TextStyle(
                        color: AppColors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.4,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      user?.email ?? '',
                      style: const TextStyle(
                        color: AppColors.secondaryText,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // AI Quota Section
              const Text(
                'Cuota de IA diaria',
                style: TextStyle(
                  color: AppColors.primaryText,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 10),
              AppCard(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              PhosphorIconsRegular.sparkle,
                              size: 18,
                              color: AppColors.white,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Plan ${quota?.plan ?? user?.plan ?? 'FREE'}',
                              style: const TextStyle(
                                color: AppColors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        Text(
                          '${quota?.used ?? 0} de ${quota?.limit ?? 5} usadas',
                          style: const TextStyle(
                            color: AppColors.secondaryText,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Progress Bar
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: quota?.progressPercentage ?? 0.0,
                        minHeight: 8,
                        backgroundColor: AppColors.secondarySurface,
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          AppColors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Te quedan ${quota?.remaining ?? 5} solicitudes hoy.',
                      style: const TextStyle(
                        color: AppColors.secondaryText,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Account Options
              const Text(
                'Cuenta',
                style: TextStyle(
                  color: AppColors.primaryText,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 10),
              AppCard(
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(
                        PhosphorIconsRegular.pencilSimple,
                        color: AppColors.primaryText,
                        size: 20,
                      ),
                      title: const Text(
                        'Modificar nombre',
                        style: TextStyle(
                          color: AppColors.primaryText,
                          fontSize: 14,
                        ),
                      ),
                      trailing: const Icon(
                        PhosphorIconsRegular.caretRight,
                        size: 16,
                        color: AppColors.secondaryText,
                      ),
                      onTap: () => _showEditNameDialog(
                        context,
                        user?.name ?? '',
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Logout Button
              AppButton(
                label: 'Cerrar sesión',
                icon: PhosphorIconsRegular.signOut,
                variant: AppButtonVariant.danger,
                onPressed: () => _confirmLogout(context),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
