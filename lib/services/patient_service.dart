import '../core/network/api_client.dart';
import '../models/patient_model.dart';

class PatientService {
  final ApiClient _apiClient;

  PatientService(this._apiClient);

  Future<Patient> createPatient(Patient patient) async {
    final response = await _apiClient.post('/patients/', data: patient.toJson());
    return Patient.fromJson(response.data);
  }

  Future<Patient> getPatient(String patientId) async {
    final response = await _apiClient.get('/patients/$patientId');
    return Patient.fromJson(response.data);
  }

  Future<Patient> updatePatient(String patientId, Map<String, dynamic> data) async {
    final response = await _apiClient.patch('/patients/$patientId', data: data);
    return Patient.fromJson(response.data);
  }
}
