import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/network/api_exception.dart';
import '../data/subscription_api_service.dart';
import '../models/subscription_info.dart';

class SubscriptionState {
  final SubscriptionInfo? subscriptionInfo;
  final bool isLoading;
  final bool isProcessing;
  final String? errorMessage;
  final String? checkoutUrl;

  const SubscriptionState({
    this.subscriptionInfo,
    this.isLoading = false,
    this.isProcessing = false,
    this.errorMessage,
    this.checkoutUrl,
  });

  SubscriptionState copyWith({
    SubscriptionInfo? subscriptionInfo,
    bool? isLoading,
    bool? isProcessing,
    String? errorMessage,
    String? checkoutUrl,
    bool clearError = false,
  }) {
    return SubscriptionState(
      subscriptionInfo: subscriptionInfo ?? this.subscriptionInfo,
      isLoading: isLoading ?? this.isLoading,
      isProcessing: isProcessing ?? this.isProcessing,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      checkoutUrl: checkoutUrl ?? this.checkoutUrl,
    );
  }
}

final subscriptionViewModelProvider =
    NotifierProvider<SubscriptionViewModel, SubscriptionState>(
  SubscriptionViewModel.new,
);

class SubscriptionViewModel extends Notifier<SubscriptionState> {
  SubscriptionApiService get _service => ref.read(subscriptionApiServiceProvider);

  @override
  SubscriptionState build() {
    return const SubscriptionState();
  }

  Future<void> loadSubscription() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final info = await _service.getMySubscription();
      state = state.copyWith(isLoading: false, subscriptionInfo: info);
    } on ApiException catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.message);
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Error al consultar suscripción.',
      );
    }
  }

  Future<bool> subscribe() async {
    state = state.copyWith(isProcessing: true, clearError: true);
    try {
      final res = await _service.createSubscription();
      final initPoint = res['initPoint'] as String?;
      state = state.copyWith(isProcessing: false, checkoutUrl: initPoint);

      if (initPoint != null && initPoint.isNotEmpty) {
        final uri = Uri.parse(initPoint);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
          return true;
        } else {
          state = state.copyWith(
            errorMessage: 'No se pudo abrir el navegador para continuar con la suscripción.',
          );
          return false;
        }
      }
      return false;
    } on ApiException catch (e) {
      state = state.copyWith(isProcessing: false, errorMessage: e.message);
      return false;
    } catch (e) {
      state = state.copyWith(
        isProcessing: false,
        errorMessage: 'Error al iniciar suscripción.',
      );
      return false;
    }
  }

  Future<bool> cancel() async {
    state = state.copyWith(isProcessing: true, clearError: true);
    try {
      await _service.cancelSubscription();
      await loadSubscription();
      state = state.copyWith(isProcessing: false);
      return true;
    } on ApiException catch (e) {
      state = state.copyWith(isProcessing: false, errorMessage: e.message);
      return false;
    } catch (_) {
      state = state.copyWith(
        isProcessing: false,
        errorMessage: 'Error al cancelar la suscripción.',
      );
      return false;
    }
  }
}
