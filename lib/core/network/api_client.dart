import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../config/env.dart';

class ApiClient {
  final Dio _dio;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  ApiClient()
      : _dio = Dio(BaseOptions(
          baseUrl: Env.apiBaseUrl,
          connectTimeout: const Duration(seconds: 120),
          receiveTimeout: const Duration(seconds: 120),
        )) {
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await _storage.read(key: 'access_token');
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options);
      },
      onError: (DioException e, handler) {
        // Here you can handle global errors like 401 logouts
        return handler.next(e);
      },
    ));
  }

  Dio get dio => _dio;

  // GET wrapper
  Future<Response> get(String path,
      {Map<String, dynamic>? queryParameters, Duration? timeout}) async {
    return await _dio.get(path,
        queryParameters: queryParameters,
        options: timeout != null
            ? Options(receiveTimeout: timeout, sendTimeout: timeout)
            : null);
  }

  // POST wrapper
  Future<Response> post(String path,
      {dynamic data,
      Map<String, dynamic>? queryParameters,
      Duration? timeout}) async {
    return await _dio.post(path,
        data: data,
        queryParameters: queryParameters,
        options: timeout != null
            ? Options(receiveTimeout: timeout, sendTimeout: timeout)
            : null);
  }

  // PUT wrapper
  Future<Response> put(String path,
      {dynamic data,
      Map<String, dynamic>? queryParameters,
      Duration? timeout}) async {
    return await _dio.put(path,
        data: data,
        queryParameters: queryParameters,
        options: timeout != null
            ? Options(receiveTimeout: timeout, sendTimeout: timeout)
            : null);
  }

  // PATCH wrapper
  Future<Response> patch(String path,
      {dynamic data,
      Map<String, dynamic>? queryParameters,
      Duration? timeout}) async {
    return await _dio.patch(path,
        data: data,
        queryParameters: queryParameters,
        options: timeout != null
            ? Options(receiveTimeout: timeout, sendTimeout: timeout)
            : null);
  }

  // DELETE wrapper
  Future<Response> delete(String path,
      {Map<String, dynamic>? queryParameters, Duration? timeout}) async {
    return await _dio.delete(path,
        queryParameters: queryParameters,
        options: timeout != null
            ? Options(receiveTimeout: timeout, sendTimeout: timeout)
            : null);
  }
}
