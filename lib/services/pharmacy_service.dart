import '../core/network/api_client.dart';
import '../models/medication_model.dart';

class PharmacyService {
  final ApiClient _apiClient;

  PharmacyService(this._apiClient);

  Future<void> saveMedications(
      String patientId, List<Medication> medications) async {
    await _apiClient.post('/pharmacy/save-medications', data: {
      'patient_id': patientId,
      'medications': medications.map((m) => m.toJson()).toList(),
    });
  }

  Future<Map<String, dynamic>> scanPrescription(
      String patientId, String base64Image) async {
    final response =
        await _apiClient.post('/pharmacy/scan-prescription', data: {
      'patient_id': patientId,
      'image_base64': base64Image,
      'media_type': 'image/jpeg',
    });
    return response.data;
  }

  Future<Map<String, dynamic>> suggestSchedule(
      String patientId, List<Medication> newMedications) async {
    final response = await _apiClient.post('/pharmacy/suggest-schedule', data: {
      'patient_id': patientId,
      'new_medications': newMedications
          .map((m) => {
                'name': m.name,
                'active_ingredient': m.activeIngredient,
                'dosage_frequency': m.dosage,
                'is_primary': m.isPrimary,
              })
          .toList(),
    });
    return response.data; // Includes explanation and suggestions list
  }

  Future<List<Medication>> getMedications(String patientId) async {
    final response = await _apiClient.get('/pharmacy/medications/$patientId');
    final List<dynamic> data = response.data;
    return data.map((m) => Medication.fromJson(m)).toList();
  }

  Future<void> deleteMedication(String patientId, String medId) async {
    await _apiClient.delete('/pharmacy/medications/$patientId/$medId');
  }

  Future<Map<String, dynamic>> checkInteractions(
      List<Medication> medications) async {
    final response =
        await _apiClient.post('/pharmacy/check-interactions', data: {
      'medications': medications
          .map((m) => {
                'name': m.name,
                'active_ingredient': m.activeIngredient,
              })
          .toList(),
    });
    return response.data;
  }
}
