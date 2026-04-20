import '../core/network/api_client.dart';
import '../models/chat_model.dart';

class ChatService {
  final ApiClient _apiClient;

  ChatService(this._apiClient);

  Future<Map<String, dynamic>> sendMessage({
    required String patientId,
    required String message,
    String? imageBase64,
    String language = 'ar',
  }) async {
    final response = await _apiClient.post('/chat/', data: {
      'patient_id': patientId,
      'message': message,
      'image_base64': imageBase64,
      'language': language,
    });
    return response.data;
  }

  Future<List<ChatMessage>> getHistory(String patientId, {int limit = 50}) async {
    final response = await _apiClient.get('/chat/$patientId/history', queryParameters: {'limit': limit});
    final List<dynamic> messages = response.data['messages'] ?? [];
    return messages.map((m) => ChatMessage.fromJson(m)).toList();
  }
}
