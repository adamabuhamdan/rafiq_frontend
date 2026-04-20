import 'package:dio/dio.dart';

class NetworkException implements Exception {
  final String message;
  final int? statusCode;

  NetworkException(this.message, {this.statusCode});

  @override
  String toString() => message;
}

class ApiExceptionHandler {
  static NetworkException handle(DioException error) {
    String message = "Unexpected error occurred";
    
    if (error.type == DioExceptionType.connectionTimeout || 
        error.type == DioExceptionType.receiveTimeout) {
      message = "Connection timed out. Please check your internet.";
    } else if (error.type == DioExceptionType.badResponse) {
      final data = error.response?.data;
      if (data is Map && data.containsKey('detail')) {
        message = data['detail'].toString();
      } else {
        message = "Server error: ${error.response?.statusCode}";
      }
    } else if (error.type == DioExceptionType.connectionError) {
      message = "No internet connection detected.";
    }

    return NetworkException(message, statusCode: error.response?.statusCode);
  }
}
