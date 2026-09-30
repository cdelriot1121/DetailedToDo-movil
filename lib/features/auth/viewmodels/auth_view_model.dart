import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_exception.dart';
import '../../events/viewmodels/events_view_model.dart';
import '../../home/viewmodels/home_view_model.dart';
import '../../notes/viewmodels/notes_view_model.dart';
import '../../profile/viewmodels/profile_view_model.dart';
import '../../tasks/viewmodels/tasks_view_model.dart';
import '../data/auth_repository.dart';
import '../models/user.dart';

enum AuthStatus {
  initial,
  loading,
  authenticated,
  unauthenticated,
  error,
}

class AuthState {
  final AuthStatus status;
  final User? user;
  final String? errorMessage;

  const AuthState({
    this.status = AuthStatus.initial,
    this.user,
    this.errorMessage,
  });

  bool get isAuthenticated => status == AuthStatus.authenticated && user != null;
  bool get isLoading => status == AuthStatus.loading;

  AuthState copyWith({
    AuthStatus? status,
    User? user,
    String? errorMessage,
    bool clearError = false,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

final authViewModelProvider =
    NotifierProvider<AuthViewModel, AuthState>(AuthViewModel.new);

class AuthViewModel extends Notifier<AuthState> {
  AuthRepository get _repository => ref.read(authRepositoryProvider);

  @override
  AuthState build() {
    return const AuthState();
  }

  Future<void> checkAuth() async {
    state = state.copyWith(status: AuthStatus.loading, clearError: true);
    try {
      final user = await _repository.checkAuth();
      if (user != null) {
        state = state.copyWith(
          status: AuthStatus.authenticated,
          user: user,
          clearError: true,
        );
      } else {
        state = state.copyWith(
          status: AuthStatus.unauthenticated,
          user: null,
          clearError: true,
        );
      }
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.unauthenticated,
        user: null,
        errorMessage: e.toString(),
      );
    }
  }

  Future<bool> login(String email, String password) async {
    state = state.copyWith(status: AuthStatus.loading, clearError: true);
    try {
      final user = await _repository.login(email.trim(), password);
      state = state.copyWith(
        status: AuthStatus.authenticated,
        user: user,
        clearError: true,
      );
      ref.invalidate(tasksViewModelProvider);
      ref.invalidate(notesViewModelProvider);
      ref.invalidate(eventsViewModelProvider);
      ref.invalidate(homeViewModelProvider);
      ref.invalidate(profileViewModelProvider);
      return true;
    } on ApiException catch (e) {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: e.message,
      );
      return false;
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: 'Error al iniciar sesión. Inténtalo de nuevo.',
      );
      return false;
    }
  }

  Future<bool> register(String name, String email, String password) async {
    state = state.copyWith(status: AuthStatus.loading, clearError: true);
    try {
      await _repository.register(name.trim(), email.trim(), password);
      state = state.copyWith(
        status: AuthStatus.unauthenticated,
        clearError: true,
      );
      return true;
    } on ApiException catch (e) {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: e.message,
      );
      return false;
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: 'Error al registrar usuario.',
      );
      return false;
    }
  }

  Future<bool> verifyOtp(String email, String code) async {
    state = state.copyWith(status: AuthStatus.loading, clearError: true);
    try {
      final user = await _repository.verifyOtp(email.trim(), code.trim());
      state = state.copyWith(
        status: AuthStatus.authenticated,
        user: user,
        clearError: true,
      );
      ref.invalidate(tasksViewModelProvider);
      ref.invalidate(notesViewModelProvider);
      ref.invalidate(eventsViewModelProvider);
      ref.invalidate(homeViewModelProvider);
      ref.invalidate(profileViewModelProvider);
      return true;
    } on ApiException catch (e) {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: e.message,
      );
      return false;
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: 'Código inválido o expirado.',
      );
      return false;
    }
  }

  Future<void> logout() async {
    await _repository.logout();
    ref.invalidate(tasksViewModelProvider);
    ref.invalidate(notesViewModelProvider);
    ref.invalidate(eventsViewModelProvider);
    ref.invalidate(homeViewModelProvider);
    ref.invalidate(profileViewModelProvider);
    state = const AuthState(status: AuthStatus.unauthenticated);
  }

  void setUser(User user) {
    state = state.copyWith(user: user);
  }

  void clearError() {
    state = state.copyWith(clearError: true);
  }
}
