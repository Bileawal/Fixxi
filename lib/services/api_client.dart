import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../core/constants/api_config.dart';

class ApiClient {
  ApiClient() {
    _dio = _buildDio(ApiConfig.api);
  }

  late Dio _dio;
  final _storage = const FlutterSecureStorage();

  Dio _buildDio(String baseUrl) {
    final dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 60),
        receiveTimeout: const Duration(seconds: 60),
        headers: {'Content-Type': 'application/json'},
      ),
    );

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await _storage.read(key: 'token');
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
      ),
    );
    return dio;
  }

  void applyBaseUrl(String baseUrl) {
    ApiConfig.setBaseUrl(baseUrl);
    _dio = _buildDio(ApiConfig.api);
  }

  Dio get dio => _dio;

  Dio _child(String baseUrl) {
    final child = Dio(_dio.options.copyWith(baseUrl: baseUrl));
    child.interceptors.addAll(_dio.interceptors);
    return child;
  }

  Dio get authDio => _child(ApiConfig.authBase);
  Dio get adminDio => _child(ApiConfig.adminBase);
  Dio get testDio => _child(ApiConfig.testBase);

  Future<void> setToken(String? token) async {
    if (token == null) {
      await _storage.delete(key: 'token');
    } else {
      await _storage.write(key: 'token', value: token);
    }
  }

  Future<String?> getToken() => _storage.read(key: 'token');
}
