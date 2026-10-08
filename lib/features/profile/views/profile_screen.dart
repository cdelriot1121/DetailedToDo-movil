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

  Widget _sectionTitle(String text) {
    return Text(
      text,
      style: TextStyle(
        color: context.palette.primaryText,
        fontSize: 14,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  void _showEditNameDialog(BuildContext context, String currentName) {
    final controller = TextEditingController(text: currentName);

    showDialog(
      context: context,
      builder: (ctx) {
        final palette = ctx.palette;
        return AlertDialog(
          backgroundColor: palette.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: BorderSide(color: palette.border),
          ),
          title: Text(
            'Editar nombre',
            style: TextStyle(color: palette.primaryText),
          ),
          content: TextField(
            controller: controller,
            autofocus: true,
            style: TextStyle(color: palette.primaryText),
            decoration: const InputDecoration(hintText: 'Tu nombre completo'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(
                'Cancelar',
                style: TextStyle(color: palette.secondaryText),
              ),
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
              child: Text(
                'Guardar',
                style: TextStyle(
                  color: palette.accent,
                  fontWeight: FontWeight.bold,
                ),
              ),
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
        final palette = ctx.palette;
        return AlertDialog(
          backgroundColor: palette.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: BorderSide(color: palette.border),
          ),
          title: Text(
            '¿Cerrar sesión?',
            style: TextStyle(color: palette.primaryText),
          ),
          content: Text(
            'Tendrás que ingresar tus credenciales nuevamente para acceder.',
            style: TextStyle(color: palette.secondaryText),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(
                'Cancelar',
                style: TextStyle(color: palette.secondaryText),
              ),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(ctx);
                await ref.read(authViewModelProvider.notifier).logout();
                if (context.mounted) {
                  context.go('/login');
                }
              },
              child: const Text(
                'Cerrar sesión',
                style: TextStyle(
                  color: AppColors.error,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(profileViewModelProvider);
    final selectedTheme = ref.watch(appThemeProvider);
    final palette = context.palette;

    if (state.isLoading && state.user == null) {
      return Scaffold(
        backgroundColor: palette.scaffoldBackground,
        body: const LoadingView(message: 'Cargando perfil...'),
      );
    }

    final user = state.user;
    final quota = state.quota;

    return Scaffold(
      backgroundColor: palette.scaffoldBackground,
      appBar: AppBar(title: const Text('Perfil')),
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
                        color: palette.accent,
                        shape: BoxShape.circle,
                        border: Border.all(color: palette.border, width: 1.5),
                      ),
                      child: Center(
                        child: Text(
                          (user?.name.isNotEmpty == true)
                              ? user!.name[0].toUpperCase()
                              : 'U',
                          style: TextStyle(
                            color: palette.onAccent,
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      user?.name ?? 'Usuario',
                      style: TextStyle(
                        color: palette.primaryText,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.4,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      user?.email ?? '',
                      style: TextStyle(
                        color: palette.secondaryText,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // AI Quota Section
              _sectionTitle('Cuota de IA diaria'),
              const SizedBox(height: 10),
              AppCard(
                backgroundColor: palette.accentContainer,
                borderColor: palette.accentContainer,
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(
                              PhosphorIconsRegular.sparkle,
                              size: 18,
                              color: palette.onAccentContainer,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Plan ${quota?.plan ?? user?.plan ?? 'FREE'}',
                              style: TextStyle(
                                color: palette.onAccentContainer,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        Text(
                          '${quota?.used ?? 0} de ${quota?.limit ?? 5} usadas',
                          style: TextStyle(
                            color: palette.onAccentContainerMuted,
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
                        backgroundColor: palette.onAccentContainer.withValues(
                          alpha: 0.22,
                        ),
                        valueColor: AlwaysStoppedAnimation<Color>(
                          palette.onAccentContainer,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Te quedan ${quota?.remaining ?? 5} solicitudes hoy.',
                      style: TextStyle(
                        color: palette.onAccentContainerMuted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Personalización
              _sectionTitle('Personalización'),
              const SizedBox(height: 10),
              AppCard(
                padding: EdgeInsets.zero,
                child: ListTile(
                  leading: Icon(
                    PhosphorIconsRegular.fadersHorizontal,
                    color: palette.primaryText,
                    size: 20,
                  ),
                  title: Text(
                    'Tema de la aplicación',
                    style: TextStyle(
                      color: palette.primaryText,
                      fontSize: 14,
                    ),
                  ),
                  subtitle: Text(
                    selectedTheme.label,
                    style: TextStyle(
                      color: palette.secondaryText,
                      fontSize: 12.5,
                    ),
                  ),
                  trailing: Icon(
                    PhosphorIconsRegular.caretRight,
                    size: 16,
                    color: palette.secondaryText,
                  ),
                  onTap: () => context.push('/profile/customization'),
                ),
              ),
              const SizedBox(height: 24),

              // Account Options
              _sectionTitle('Cuenta'),
              const SizedBox(height: 10),
              AppCard(
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    ListTile(
                      leading: Icon(
                        PhosphorIconsRegular.pencilSimple,
                        color: palette.primaryText,
                        size: 20,
                      ),
                      title: Text(
                        'Modificar nombre',
                        style: TextStyle(
                          color: palette.primaryText,
                          fontSize: 14,
                        ),
                      ),
                      trailing: Icon(
                        PhosphorIconsRegular.caretRight,
                        size: 16,
                        color: palette.secondaryText,
                      ),
                      onTap: () =>
                          _showEditNameDialog(context, user?.name ?? ''),
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
