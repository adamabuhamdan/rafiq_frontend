import '../core/network/api_client.dart';

class ReportService {
  final ApiClient _apiClient;

  ReportService(this._apiClient);

  Future<Map<String, dynamic>> submitDailyReport(Map<String, dynamic> data) async {
    final response = await _apiClient.post(
      '/reports/daily-report',
      data: data,
      timeout: const Duration(minutes: 2),
    );
    return response.data;
  }

  Future<Map<String, dynamic>?> getTodayReport(String patientId) async {
    try {
      final response = await _apiClient.get('/reports/today/$patientId');
      return response.data;
    } catch (e) {
      return null;
    }
  }

  Future<Map<String, dynamic>> getWeeklyReport(String patientId, List<String> events, {String? doctorEmail, String language = 'ar'}) async {
    final response = await _apiClient.post(
      '/reports/weekly-doctor-report',
      data: {
        'patient_id': patientId,
        'weekly_events': events,
        'doctor_email': doctorEmail,
        'language': language,
      },
      timeout: const Duration(minutes: 2),
    );
    return response.data;
  }
}

class SettingsService {
  final ApiClient _apiClient;

  SettingsService(this._apiClient);

  Future<Map<String, dynamic>> getSettings(String patientId) async {
    final response = await _apiClient.get('/settings/$patientId');
    return response.data;
  }

  Future<Map<String, dynamic>> updateSettings(String patientId, Map<String, dynamic> data) async {
    final response = await _apiClient.put('/settings/$patientId', data: data);
    return response.data;
  }
}
