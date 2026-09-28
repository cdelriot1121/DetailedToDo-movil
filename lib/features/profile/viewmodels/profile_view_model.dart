import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_exception.dart';
import '../../../shared/models/ai_quota.dart';
import '../../auth/models/user.dart';
import '../data/user_repository.dart';

class ProfileState {
  final User? user;
  final AIQuota? quota;
  final bool isLoading;
  final bool isSaving;
  final String? errorMessage;

  const ProfileState({
    this.user,
    this.quota,
    this.isLoading = false,
    this.isSaving = false,
    this.errorMessage,
  });

  ProfileState copyWith({
    User? user,
    AIQuota? quota,
    bool? isLoading,
    bool? isSaving,
    String? errorMessage,
    bool clearError = false,
  }) {
    return ProfileState(
      user: user ?? this.user,
      quota: quota ?? this.quota,
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

final profileViewModelProvider =
    NotifierProvider<ProfileViewModel, ProfileState>(ProfileViewModel.new);

class ProfileViewModel extends Notifier<ProfileState> {
  UserRepository get _repository => ref.read(userRepositoryProvider);

  @override
  ProfileState build() {
    Future.microtask(() => loadProfile());
    return const ProfileState();
  }

  Future<void> loadProfile() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final results = await Future.wait([
        _repository.getProfile(),
        _repository.getAIQuota().catchError(
              (_) => const AIQuota(used: 0, limit: 5, remaining: 5, plan: 'FREE'),
            ),
      ]);

      state = state.copyWith(
        isLoading: false,
        user: results[0] as User,
        quota: results[1] as AIQuota,
      );
    } on ApiException catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.message);
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Error al cargar perfil.',
      );
    }
  }

  Future<bool> updateProfile({String? name, String? email}) async {
    state = state.copyWith(isSaving: true, clearError: true);
    try {
      final updatedUser = await _repository.updateProfile(
        name: name,
        email: email,
      );
      state = state.copyWith(isSaving: false, user: updatedUser);
      return true;
    } on ApiException catch (e) {
      state = state.copyWith(isSaving: false, errorMessage: e.message);
      return false;
    } catch (_) {
      state = state.copyWith(
        isSaving: false,
        errorMessage: 'Error al actualizar perfil.',
      );
      return false;
    }
  }
}
