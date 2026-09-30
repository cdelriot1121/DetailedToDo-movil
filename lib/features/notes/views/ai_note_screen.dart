import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import '../../../app/theme.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/voice_input_widget.dart';
import '../data/note_repository.dart';
import '../viewmodels/notes_view_model.dart';

class AINoteScreen extends ConsumerStatefulWidget {
  const AINoteScreen({super.key});

  @override
  ConsumerState<AINoteScreen> createState() => _AINoteScreenState();
}

class _AINoteScreenState extends ConsumerState<AINoteScreen> {
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
      final repository = ref.read(noteRepositoryProvider);
      final createdNote = await repository.createNoteWithAI(text);

      ref.read(notesViewModelProvider.notifier).loadNotes();

      if (mounted) {
        context.pushReplacement('/notes/${createdNote.id}', extra: createdNote);
      }
    } on ApiException catch (e) {
      setState(() {
        _errorMessage = e.message;
        _isLoading = false;
      });
    } catch (_) {
      setState(() {
        _errorMessage = 'No pudimos estructurar la nota con IA.';
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
            Text('Nota con IA'),
          ],
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Escribe tus pensamientos o ideas sueltas',
                style: TextStyle(
                  color: AppColors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.4,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'La IA organizará un título descriptivo, cuerpo estructurado, carpeta y etiquetas relevantes.',
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
                      _contentController.text = '${_contentController.text.trim()} $text';
                    }
                  });
                },
              ),
              const SizedBox(height: 20),

              AppButton(
                label: _isLoading ? 'Organizando nota...' : 'Generar nota con IA',
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
