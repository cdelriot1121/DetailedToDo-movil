import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import '../../../app/theme.dart';
import '../viewmodels/auth_view_model.dart';

class OnboardingOccupationScreen extends ConsumerStatefulWidget {
  const OnboardingOccupationScreen({super.key});

  @override
  ConsumerState<OnboardingOccupationScreen> createState() =>
      _OnboardingOccupationScreenState();
}

class _OnboardingOccupationScreenState
    extends ConsumerState<OnboardingOccupationScreen> {
  final List<String> _predefinedOptions = const [
    'Ingeniería',
    'Administración',
    'Desarrollador',
    'Empleado',
    'Estudiante',
    'Uso personal',
  ];

  final Set<String> _selectedOptions = {};
  bool _isOtherSelected = false;
  final TextEditingController _otherController = TextEditingController();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final user = ref.read(authViewModelProvider).user;
    if (user?.preferenciasOficio != null) {
      for (final item in user!.preferenciasOficio!) {
        if (_predefinedOptions.contains(item)) {
          _selectedOptions.add(item);
        } else if (item.isNotEmpty) {
          _isOtherSelected = true;
          _otherController.text = item;
        }
      }
    }
  }

  @override
  void dispose() {
    _otherController.dispose();
    super.dispose();
  }

  int get _totalSelectedCount {
    int count = _selectedOptions.length;
    if (_isOtherSelected && _otherController.text.trim().isNotEmpty) {
      count++;
    } else if (_isOtherSelected && _otherController.text.trim().isEmpty) {
      count++;
    }
    return count;
  }

  void _toggleOption(String option) {
    setState(() {
      if (_selectedOptions.contains(option)) {
        _selectedOptions.remove(option);
      } else {
        if (_totalSelectedCount >= 3) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Puedes seleccionar un máximo de 3 opciones.'),
              backgroundColor: context.palette.accent,
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 2),
            ),
          );
          return;
        }
        _selectedOptions.add(option);
      }
    });
  }

  void _toggleOther() {
    setState(() {
      if (_isOtherSelected) {
        _isOtherSelected = false;
        _otherController.clear();
      } else {
        if (_totalSelectedCount >= 3) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Puedes seleccionar un máximo de 3 opciones.'),
              backgroundColor: context.palette.accent,
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 2),
            ),
          );
          return;
        }
        _isOtherSelected = true;
      }
    });
  }

  Future<void> _saveAndProceed(List<String> listToSave) async {
    setState(() => _isSaving = true);
    final success = await ref
        .read(authViewModelProvider.notifier)
        .updatePreferences(listToSave);

    if (!mounted) return;
    setState(() => _isSaving = false);

    if (success) {
      context.go('/home');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se pudieron guardar tus preferencias.'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  void _onSubmit() {
    final List<String> result = List.from(_selectedOptions);
    if (_isOtherSelected) {
      final customText = _otherController.text.trim();
      if (customText.isNotEmpty) {
        result.add(customText.length > 15 ? customText.substring(0, 15) : customText);
      }
    }
    _saveAndProceed(result);
  }

  void _onSkip() {
    // Si omite, guardamos lista vacía [] para que quede registrado y no se le vuelva a preguntar
    _saveAndProceed(const []);
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return Scaffold(
      backgroundColor: palette.scaffoldBackground,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _onSkip,
            child: Text(
              'Omitir',
              style: TextStyle(
                color: palette.secondaryText,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: palette.accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  PhosphorIconsRegular.sparkle,
                  color: palette.accent,
                  size: 28,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Personaliza tu experiencia',
                style: TextStyle(
                  color: palette.primaryText,
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '¿A qué te dedicas? Selecciona hasta 3 opciones para que la Inteligencia Artificial adapte tus notas, subtareas y eventos a tu ritmo.',
                style: TextStyle(
                  color: palette.secondaryText,
                  fontSize: 14,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 24),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  ..._predefinedOptions.map((opt) {
                    final isSelected = _selectedOptions.contains(opt);
                    return FilterChip(
                      selected: isSelected,
                      label: Text(opt),
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : palette.primaryText,
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                      ),
                      backgroundColor: palette.surface,
                      selectedColor: palette.accent,
                      checkmarkColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                        side: BorderSide(
                          color: isSelected
                              ? palette.accent
                              : palette.divider.withValues(alpha: 0.5),
                        ),
                      ),
                      onSelected: (_) => _toggleOption(opt),
                    );
                  }),
                  FilterChip(
                    selected: _isOtherSelected,
                    label: const Text('Otro'),
                    labelStyle: TextStyle(
                      color: _isOtherSelected ? Colors.white : palette.primaryText,
                      fontWeight:
                          _isOtherSelected ? FontWeight.w700 : FontWeight.w500,
                    ),
                    backgroundColor: palette.surface,
                    selectedColor: palette.accent,
                    checkmarkColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: BorderSide(
                        color: _isOtherSelected
                            ? palette.accent
                            : palette.divider.withValues(alpha: 0.5),
                      ),
                    ),
                    onSelected: (_) => _toggleOther(),
                  ),
                ],
              ),
              if (_isOtherSelected) ...[
                const SizedBox(height: 20),
                TextField(
                  controller: _otherController,
                  maxLength: 15,
                  decoration: InputDecoration(
                    labelText: 'Escribe tu oficio',
                    labelStyle: TextStyle(color: palette.secondaryText),
                    hintText: 'Ej. Diseñador, Médico',
                    hintStyle: TextStyle(color: palette.placeholder),
                    counterStyle: TextStyle(color: palette.secondaryText),
                    filled: true,
                    fillColor: palette.surface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: palette.border),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: palette.accent, width: 2),
                    ),
                  ),
                  style: TextStyle(color: palette.primaryText),
                ),
              ],
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _onSubmit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: palette.accent,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Continuar',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
