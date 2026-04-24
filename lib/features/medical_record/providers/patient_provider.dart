import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/patient_model.dart';
import '../../../services/patient_service.dart';
import '../../../providers/network_provider.dart';
import '../../auth/providers/auth_provider.dart';

final patientServiceProvider = Provider<PatientService>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return PatientService(apiClient);
});

class PatientState {
  final Patient? patient;
  final bool isLoading;
  final String? error;

  const PatientState({this.patient, this.isLoading = false, this.error});

  PatientState copyWith({Patient? patient, bool? isLoading, String? error}) {
    return PatientState(
      patient: patient ?? this.patient,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class PatientNotifier extends Notifier<PatientState> {
  PatientService get _patientService => ref.read(patientServiceProvider);
  String? get _patientId => ref.read(authProvider).userId;

  @override
  PatientState build() {
    final patientId = ref.watch(authProvider).userId;
    if (patientId != null) {
      Future.microtask(() => _loadPatientFor(patientId));
    }
    return const PatientState();
  }

  Future<void> _loadPatientFor(String patientId) async {
    state = state.copyWith(isLoading: true);
    try {
      final patient = await _patientService.getPatient(patientId);
      state = state.copyWith(patient: patient, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> loadPatient() async {
    final patientId = _patientId;
    if (patientId == null) return;
    await _loadPatientFor(patientId);
  }

  Future<bool> saveProfile(Patient updatedPatient) async {
    final patientId = _patientId;
    state = state.copyWith(isLoading: true);
    try {
      if (state.patient == null) {
        // Create new profile if it doesn't exist yet (e.g., 404 on load)
        final created = await _patientService.createPatient(updatedPatient);
        state = PatientState(patient: created, isLoading: false, error: null);
        return true;
      } else {
        // Patch update to existing profile
        final updated = await _patientService.updatePatient(
          patientId ?? updatedPatient.id,
          updatedPatient.toJson(),
        );
        state = state.copyWith(patient: updated, isLoading: false);
        return true;
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }
}

final patientProvider = NotifierProvider<PatientNotifier, PatientState>(
  PatientNotifier.new,
);
