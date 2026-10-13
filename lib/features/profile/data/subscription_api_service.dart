import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/network/dio_client.dart';
import '../models/subscription_info.dart';

final subscriptionApiServiceProvider = Provider<SubscriptionApiService>((ref) {
  return SubscriptionApiService(ref.watch(dioClientProvider));
});

class SubscriptionApiService {
  final Dio _dio;

  SubscriptionApiService(this._dio);

  Future<Map<String, dynamic>> createSubscription() async {
    try {
      final response = await _dio.post('subscriptions/create');
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<SubscriptionInfo> getMySubscription() async {
    try {
      final response = await _dio.get('subscriptions/me');
      return SubscriptionInfo.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<Map<String, dynamic>> cancelSubscription() async {
    try {
      final response = await _dio.post('subscriptions/cancel');
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }
}
