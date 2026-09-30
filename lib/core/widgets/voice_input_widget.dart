import 'dart:async';
import 'package:flutter/material.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';
import '../../app/theme.dart';

class VoiceInputWidget extends StatefulWidget {
  final ValueChanged<String> onTranscriptionComplete;
  final ValueChanged<String>? onTranscriptionUpdate;
  final int maxDurationSeconds;

  const VoiceInputWidget({
    super.key,
    required this.onTranscriptionComplete,
    this.onTranscriptionUpdate,
    this.maxDurationSeconds = 15,
  });

  @override
  State<VoiceInputWidget> createState() => _VoiceInputWidgetState();
}

class _VoiceInputWidgetState extends State<VoiceInputWidget>
    with SingleTickerProviderStateMixin {
  final SpeechToText _speech = SpeechToText();
  bool _isSpeechAvailable = false;
  bool _isListening = false;
  int _remainingSeconds = 15;
  Timer? _timer;
  String _currentWords = '';
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _remainingSeconds = widget.maxDurationSeconds;
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.25).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _initSpeech();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pulseController.dispose();
    _speech.stop();
    super.dispose();
  }

  Future<void> _initSpeech() async {
    try {
      final available = await _speech.initialize(
        onError: _onSpeechError,
        onStatus: _onSpeechStatus,
      );
      if (mounted) {
        setState(() {
          _isSpeechAvailable = available;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isSpeechAvailable = false;
        });
      }
    }
  }

  void _onSpeechError(SpeechRecognitionError error) {
    if (mounted) {
      setState(() {
        _isListening = false;
      });
      _timer?.cancel();
      if (_currentWords.isNotEmpty) {
        widget.onTranscriptionComplete(_currentWords.trim());
      }
    }
  }

  void _onSpeechStatus(String status) {
    if (status == 'done' || status == 'notListening') {
      if (_isListening && mounted) {
        _stopListening();
      }
    }
  }

  void _startListening() async {
    if (!_isSpeechAvailable) {
      await _initSpeech();
      if (!_isSpeechAvailable) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'El micrófono o reconocimiento de voz no está disponible o requiere permisos en el navegador/dispositivo.',
              ),
              backgroundColor: AppColors.error,
            ),
          );
        }
        return;
      }
    }

    _currentWords = '';
    setState(() {
      _isListening = true;
      _remainingSeconds = widget.maxDurationSeconds;
    });

    try {
      await _speech.listen(
        onResult: (SpeechRecognitionResult result) {
          setState(() {
            _currentWords = result.recognizedWords;
          });
          widget.onTranscriptionUpdate?.call(_currentWords);
        },
        listenOptions: SpeechListenOptions(
          listenFor: Duration(seconds: widget.maxDurationSeconds),
          pauseFor: const Duration(seconds: 4),
          localeId: 'es_ES',
          cancelOnError: false,
          partialResults: true,
          listenMode: ListenMode.dictation,
        ),
      );

      _timer?.cancel();
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (_remainingSeconds > 1) {
          setState(() {
            _remainingSeconds--;
          });
        } else {
          _stopListening();
        }
      });
    } catch (e) {
      setState(() {
        _isListening = false;
      });
      _timer?.cancel();
    }
  }

  void _stopListening() async {
    _timer?.cancel();
    await _speech.stop();
    if (mounted) {
      setState(() {
        _isListening = false;
        _remainingSeconds = widget.maxDurationSeconds;
      });
      if (_currentWords.trim().isNotEmpty) {
        widget.onTranscriptionComplete(_currentWords.trim());
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isListening) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.primarySurface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.white.withValues(alpha: 0.3), width: 1.2),
        ),
        child: Row(
          children: [
            ScaleTransition(
              scale: _pulseAnimation,
              child: Container(
                width: 32,
                height: 32,
                decoration: const BoxDecoration(
                  color: AppColors.error,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  PhosphorIconsFill.microphone,
                  color: AppColors.white,
                  size: 18,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Grabando nota de voz...',
                        style: TextStyle(
                          color: AppColors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        '00:${_remainingSeconds.toString().padLeft(2, '0')}',
                        style: const TextStyle(
                          color: AppColors.error,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _currentWords.isNotEmpty
                      ? _currentWords
                      : 'Escuchando tu voz en español (máx. 15s)...',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.secondaryText,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: _stopListening,
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.secondarySurface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.border),
                ),
                child: const Icon(
                  PhosphorIconsFill.stop,
                  color: AppColors.white,
                  size: 16,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return GestureDetector(
      onTap: _startListening,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.secondarySurface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.border),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              PhosphorIconsRegular.microphone,
              color: AppColors.white,
              size: 18,
            ),
            SizedBox(width: 8),
            Text(
              'Dictar con voz (15s máx)',
              style: TextStyle(
                color: AppColors.white,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
