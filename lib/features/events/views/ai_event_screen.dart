import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import '../../../app/theme.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_text_field.dart';
import '../data/event_repository.dart';
import '../viewmodels/events_view_model.dart';

class AIEventScreen extends ConsumerStatefulWidget {
  const AIEventScreen({super.key});

  @override
  ConsumerState<AIEventScreen> createState() => _AIEventScreenState();
}

class _AIEventScreenState extends ConsumerState<AIEventScreen> {
  final _contentController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final text = _contentController.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final repository = ref.read(eventRepositoryProvider);
      final createdEvent = await repository.createEventWithAI(text);

      ref.read(eventsViewModelProvider.notifier).loadEvents();

      if (mounted) {
        context.pushReplacement('/events/${createdEvent.id}', extra: createdEvent);
      }
    } on ApiException catch (e) {
      setState(() {
        _errorMessage = e.message;
        _isLoading = false;
      });
    } catch (_) {
      setState(() {
        _errorMessage = 'No pudimos estructurar el evento con IA.';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(PhosphorIconsRegular.sparkle, size: 20),
            SizedBox(width: 8),
            Text('Evento con IA'),
          ],
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Describe tu reunión o evento',
                style: TextStyle(
                  color: AppColors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.4,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Escribe la fecha, hora y detalles en lenguaje natural. La IA extraerá los horarios y recordatorios automáticamente.',
                style: TextStyle(
                  color: AppColors.secondaryText,
                  fontSize: 14,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 24),

              if (_errorMessage != null) ...[
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
                    _errorMessage!,
                    style: const TextStyle(
                      color: AppColors.error,
                      fontSize: 13,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              AppTextField(
                controller: _contentController,
                maxLines: 8,
                minLines: 5,
                autofocus: true,
              ),
              const SizedBox(height: 24),

              AppButton(
                label: _isLoading ? 'Agendando evento...' : 'Generar evento con IA',
                isLoading: _isLoading,
                variant: AppButtonVariant.ai,
                onPressed: _submit,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
