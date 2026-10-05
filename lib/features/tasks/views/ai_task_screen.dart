import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import '../../../app/theme.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/voice_input_widget.dart';
import '../data/task_repository.dart';
import '../viewmodels/tasks_view_model.dart';

class AITaskScreen extends ConsumerStatefulWidget {
  const AITaskScreen({super.key});

  @override
  ConsumerState<AITaskScreen> createState() => _AITaskScreenState();
}

class _AITaskScreenState extends ConsumerState<AITaskScreen> {
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
      final repository = ref.read(taskRepositoryProvider);
      final createdTask = await repository.createTaskWithAI(text);

      ref.read(tasksViewModelProvider.notifier).loadTasks();

      if (mounted) {
        // Navigate directly to the task detail screen where polling is active
        context.pushReplacement('/tasks/${createdTask.id}');
      }
    } on ApiException catch (e) {
      setState(() {
        _errorMessage = e.message;
        _isLoading = false;
      });
    } catch (_) {
      setState(() {
        _errorMessage =
            'No pudimos estructurar la tarea con IA. Inténtalo de nuevo.';
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
            Text('Crear con IA'),
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
                'Cuéntame qué necesitas hacer',
                style: TextStyle(
                  color: AppColors.primaryText,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.4,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Escribe de forma natural. La IA detectará fechas, prioridades, carpetas y creará subtareas paso a paso.',
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

              // Prompt Input Area
              AppTextField(
                controller: _contentController,
                maxLines: 7,
                minLines: 4,
                autofocus: true,
              ),
              const SizedBox(height: 12),

              // Voice input recorder (max 15s)
              VoiceInputWidget(
                onTranscriptionComplete: (text) {
                  setState(() {
                    if (_contentController.text.trim().isEmpty) {
                      _contentController.text = text;
                    } else {
                      _contentController.text =
                          '${_contentController.text.trim()} $text';
                    }
                  });
                },
                onTranscriptionUpdate: (partialText) {
                  // real-time partial feedback
                },
              ),
              const SizedBox(height: 20),

              // Creation Button
              AppButton(
                label: _isLoading
                    ? 'Organizando tu tarea...'
                    : 'Generar tarea con IA',
                isLoading: _isLoading,
                variant: AppButtonVariant.ai,
                onPressed: _submit,
              ),

              const Spacer(),

              // Quick ideas
              const Text(
                'Sugerencias rápidas:',
                style: TextStyle(
                  color: AppColors.secondaryText,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildSuggestionChip(
                    'Estudiar para el examen de cálculo el jueves a las 3pm',
                  ),
                  _buildSuggestionChip(
                    'Preparar presentación de sprint para el equipo de diseño',
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSuggestionChip(String text) {
    return GestureDetector(
      onTap: () {
        _contentController.text = text;
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.secondarySurface,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: AppColors.border),
        ),
        child: Text(
          text,
          style: const TextStyle(color: AppColors.secondaryText, fontSize: 12),
        ),
      ),
    );
  }
}
