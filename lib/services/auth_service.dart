import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../core/network/api_client.dart';

class AuthService {
  final ApiClient _apiClient;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  AuthService(this._apiClient);

  Future<void> sendOtp(String email) async {
    await _apiClient.post('/auth/send-otp', data: {'email': email});
  }

  Future<Map<String, dynamic>> verifyOtp(String email, String token) async {
    final response = await _apiClient.post('/auth/verify-otp', data: {
      'email': email,
      'token': token,
    });
    
    final data = response.data as Map<String, dynamic>;
    await _storage.write(key: 'access_token', value: data['access_token']);
    await _storage.write(key: 'user_id', value: data['user_id']);
    
    return data;
  }

  Future<void> logout() async {
    try {
      await _apiClient.post('/settings/logout');
    } catch (e) {
      // Log error or handle it if necessary, but proceed with local logout
    } finally {
      await _storage.delete(key: 'access_token');
      await _storage.delete(key: 'user_id');
    }
  }

  Future<String?> getLoggedUserId() async {
    return await _storage.read(key: 'user_id');
  }
}
