import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import '../../../app/theme.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';
import '../viewmodels/profile_view_model.dart';
import '../viewmodels/subscription_view_model.dart';

class SubscriptionModal extends ConsumerStatefulWidget {
  const SubscriptionModal({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const SubscriptionModal(),
    );
  }

  @override
  ConsumerState<SubscriptionModal> createState() => _SubscriptionModalState();
}

class _SubscriptionModalState extends ConsumerState<SubscriptionModal> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(subscriptionViewModelProvider.notifier).loadSubscription();
    });
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final subState = ref.watch(subscriptionViewModelProvider);
    final user = ref.watch(profileViewModelProvider).user;
    final isPlus = user?.isPlus ?? false;
    final expiresAt = user?.subscriptionExpiresAt;
    final dateFormat = DateFormat('dd/MM/yyyy');

    return Container(
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: palette.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Title & Badge
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: palette.accentContainer,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  PhosphorIconsFill.sparkle,
                  color: palette.accent,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'DetailedToDo Plus',
                      style: TextStyle(
                        color: palette.primaryText,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      isPlus
                          ? 'Membresía activa'
                          : 'Potencia tu productividad diaria con IA',
                      style: TextStyle(
                        color: palette.secondaryText,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Features Card
          AppCard(
            backgroundColor: palette.surfaceSecondary,
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _featureItem(
                  palette,
                  PhosphorIconsRegular.lightning,
                  '15 solicitudes diarias de IA (en vez de 5)',
                ),
                const SizedBox(height: 12),
                _featureItem(
                  palette,
                  PhosphorIconsRegular.brain,
                  'Desglose inteligente de subtareas y planes',
                ),
                const SizedBox(height: 12),
                _featureItem(
                  palette,
                  PhosphorIconsRegular.shieldCheck,
                  'Suscripción mensual recurrente vía Mercado Pago',
                ),
                const SizedBox(height: 12),
                _featureItem(
                  palette,
                  PhosphorIconsRegular.xCircle,
                  'Cancela en cualquier momento sin penalizaciones',
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Pricing & Status info
          if (isPlus) ...[
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: palette.accentContainer.withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: palette.accentContainer),
              ),
              child: Row(
                children: [
                  Icon(
                    PhosphorIconsRegular.calendarCheck,
                    color: palette.accent,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      expiresAt != null
                          ? 'Tu plan está vigente hasta el ${dateFormat.format(expiresAt)}.'
                          : 'Tu plan Plus está activo.',
                      style: TextStyle(
                        color: palette.primaryText,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            AppButton(
              label: subState.isProcessing
                  ? 'Cancelando...'
                  : 'Cancelar suscripción recurrente',
              variant: AppButtonVariant.danger,
              isLoading: subState.isProcessing,
              onPressed: () async {
                final nav = Navigator.of(context);
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    backgroundColor: palette.surface,
                    title: Text(
                      '¿Cancelar suscripción?',
                      style: TextStyle(color: palette.primaryText),
                    ),
                    content: Text(
                      'Mantendrás los beneficios Plus hasta el fin del ciclo de facturación.',
                      style: TextStyle(color: palette.secondaryText),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: const Text('Mantener'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        child: const Text(
                          'Sí, cancelar',
                          style: TextStyle(color: Colors.red),
                        ),
                      ),
                    ],
                  ),
                );

                if (confirm == true && mounted) {
                  final ok = await ref
                      .read(subscriptionViewModelProvider.notifier)
                      .cancel();
                  if (ok && mounted) {
                    await ref
                        .read(profileViewModelProvider.notifier)
                        .loadProfile();
                    nav.pop();
                  }
                }
              },
            ),
          ] else ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  '\$3.500 COP',
                  style: TextStyle(
                    color: palette.primaryText,
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  ' / mes',
                  style: TextStyle(
                    color: palette.secondaryText,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (subState.errorMessage != null) ...[
              Text(
                subState.errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.red, fontSize: 13),
              ),
              const SizedBox(height: 10),
            ],
            AppButton(
              label: subState.isProcessing
                  ? 'Conectando con Mercado Pago...'
                  : 'Suscribirme con Mercado Pago',
              icon: PhosphorIconsRegular.creditCard,
              isLoading: subState.isProcessing,
              onPressed: () async {
                final nav = Navigator.of(context);
                final messenger = ScaffoldMessenger.of(context);
                final ok = await ref
                    .read(subscriptionViewModelProvider.notifier)
                    .subscribe();
                if (ok) {
                  nav.pop();
                  messenger.showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Redirigiendo a Mercado Pago para confirmar tu suscripción...',
                      ),
                    ),
                  );
                }
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _featureItem(dynamic palette, IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 18, color: palette.accent),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              color: palette.primaryText,
              fontSize: 13.5,
            ),
          ),
        ),
      ],
    );
  }
}
