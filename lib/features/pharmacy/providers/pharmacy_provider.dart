import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../models/medication_model.dart';
import '../../../services/pharmacy_service.dart';
import '../../auth/providers/auth_provider.dart';
import '../../dashboard/providers/dashboard_provider.dart';

// State class
class PharmacyState {
  final List<Medication> medications;
  final bool isLoading;
  final String? error;

  const PharmacyState({
    this.medications = const [],
    this.isLoading = false,
    this.error,
  });

  PharmacyState copyWith({
    List<Medication>? medications,
    bool? isLoading,
    String? error,
  }) {
    return PharmacyState(
      medications: medications ?? this.medications,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

// Notifier
class PharmacyNotifier extends StateNotifier<PharmacyState> {
  final PharmacyService _pharmacyService;
  final String? _patientId;

  PharmacyNotifier(this._pharmacyService, this._patientId) : super(const PharmacyState()) {
    loadMedications();
  }

  Future<void> loadMedications() async {
    if (_patientId == null) return;
    state = state.copyWith(isLoading: true);
    try {
      final meds = await _pharmacyService.getMedications(_patientId!);
      state = state.copyWith(medications: meds, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Add a new empty medication (manual entry) with a default 08:00 alarm.
  void addNewMedication() {
    final defaultTime = DateTime(0, 0, 0, 8, 0);
    final newMed = Medication(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: '',
      activeIngredient: '',
      dosage: '',
      times: [defaultTime],
      frequency: 'daily',
    );
    state = state.copyWith(medications: [...state.medications, newMed]);
  }

  /// Update a specific medication at index.
  void updateMedication(int index, Medication updatedMed) {
    if (index < 0 || index >= state.medications.length) return;
    final updatedList = List<Medication>.from(state.medications);
    updatedList[index] = updatedMed;
    state = state.copyWith(medications: updatedList);
  }

  /// Update only the times list for a specific medication (called by alarm UI).
  void updateMedicationTimes(int index, List<DateTime> newTimes) {
    if (index < 0 || index >= state.medications.length) return;
    final sorted = List<DateTime>.from(newTimes)..sort((a, b) => a.hour != b.hour ? a.hour.compareTo(b.hour) : a.minute.compareTo(b.minute));
    final updatedList = List<Medication>.from(state.medications);
    updatedList[index] = updatedList[index].copyWith(times: sorted);
    state = state.copyWith(medications: updatedList);
  }

  /// Remove a medication at index.
  void removeMedication(int index) {
    if (index < 0 || index >= state.medications.length) return;
    final updatedList = List<Medication>.from(state.medications);
    updatedList.removeAt(index);
    state = state.copyWith(medications: updatedList);
  }

  /// Use real AI scan from Backend.
  Future<void> scanPrescription(String base64Image) async {
    if (_patientId == null) return;
    state = state.copyWith(isLoading: true);
    try {
      final result = await _pharmacyService.scanPrescription(_patientId!, base64Image);
      final extractedList = result['extracted'] as List<dynamic>;

      final List<Medication> newMeds = extractedList.map((medData) {
        return Medication(
          id: DateTime.now().microsecondsSinceEpoch.toString() + extractedList.indexOf(medData).toString(),
          name: medData['name'] ?? '',
          activeIngredient: medData['active_ingredient'] ?? '',
          dosage: '',
          times: [DateTime(0, 0, 0, 8, 0)],
          frequency: '',
        );
      }).toList();

      state = state.copyWith(
        medications: [...state.medications, ...newMeds],
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Persist medications to DB.
  Future<void> saveMedications() async {
    if (_patientId == null || state.medications.isEmpty) return;
    state = state.copyWith(isLoading: true);
    try {
      await _pharmacyService.saveMedications(_patientId!, state.medications);
      state = state.copyWith(medications: [], isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Suggest Smart Schedule via AI.
  Future<List<Medication>?> suggestSchedule() async {
    if (_patientId == null || state.medications.isEmpty) return null;
    state = state.copyWith(isLoading: true);
    try {
      final response = await _pharmacyService.suggestSchedule(_patientId!, state.medications);
      final suggestionsRaw = response['suggestions'] as List<dynamic>;

      final List<Medication> optimizedMeds = suggestionsRaw.map((s) {
        final med = Medication.fromJson(s as Map<String, dynamic>);
        return med.id.isEmpty
            ? med.copyWith(id: DateTime.now().microsecondsSinceEpoch.toString() + suggestionsRaw.indexOf(s).toString())
            : med;
      }).toList();

      state = state.copyWith(isLoading: false);
      return optimizedMeds;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      rethrow;
    }
  }

  /// Save a specific list of medications directly (used by AiScheduleScreen).
  /// Bypasses the provider state to avoid ID/length mismatch issues.
  Future<void> replaceAndSave(List<Medication> meds) async {
    if (_patientId == null || meds.isEmpty) return;
    state = state.copyWith(isLoading: true);
    try {
      await _pharmacyService.saveMedications(_patientId!, meds);
      state = state.copyWith(medications: [], isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      rethrow;
    }
  }


  void clearMedications() {
    state = const PharmacyState();
  }

  void setLoading(bool loading) {
    state = state.copyWith(isLoading: loading);
  }
}

// Provider
final pharmacyProvider = StateNotifierProvider<PharmacyNotifier, PharmacyState>((ref) {
  final pharmacyService = ref.watch(pharmacyServiceProvider);
  final authState = ref.watch(authProvider);
  return PharmacyNotifier(pharmacyService, authState.userId);
});
