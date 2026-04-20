import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/patient_model.dart';
import '../../../services/patient_service.dart';
import '../../../providers/network_provider.dart';
import '../../auth/providers/auth_provider.dart';

final patientServiceProvider = Provider<PatientService>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return PatientService(apiClient);
});

final patientProvider =
    StateNotifierProvider<PatientNotifier, PatientState>((ref) {
  final patientService = ref.watch(patientServiceProvider);
  final authState = ref.watch(authProvider);
  return PatientNotifier(patientService, authState.userId);
});

class PatientState {
  final Patient? patient;
  final bool isLoading;
  final String? error;

  const PatientState({
    this.patient,
    this.isLoading = false,
    this.error,
  });

  PatientState copyWith({
    Patient? patient,
    bool? isLoading,
    String? error,
  }) {
    return PatientState(
      patient: patient ?? this.patient,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class PatientNotifier extends StateNotifier<PatientState> {
  final PatientService _patientService;
  final String? _patientId;

  PatientNotifier(this._patientService, this._patientId)
      : super(const PatientState()) {
    if (_patientId != null) {
      loadPatient();
    }
  }

  Future<void> loadPatient() async {
    if (_patientId == null) return;
    state = state.copyWith(isLoading: true);
    try {
      final patient = await _patientService.getPatient(_patientId!);
      state = state.copyWith(patient: patient, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<bool> saveProfile(Patient updatedPatient) async {
    state = state.copyWith(isLoading: true);
    try {
      // Patch update to existing profile
      final updated = await _patientService.updatePatient(
          _patientId ?? updatedPatient.id, updatedPatient.toJson());
      state = state.copyWith(patient: updated, isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }
}
