import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/dio_client.dart';

final homeApiServiceProvider = Provider<HomeApiService>((ref) {
  return HomeApiService(ref.watch(dioClientProvider));
});

class HomeApiService {
  final Dio _dio;

  HomeApiService(this._dio);

  Future<String> getAISummary() async {
    final response = await _dio.get('/home/summary');
    return (response.data as Map<String, dynamic>)['message'] as String;
  }
}
