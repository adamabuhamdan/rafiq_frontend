import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../models/medication_model.dart';
import '../../../services/pharmacy_service.dart';
import '../../auth/providers/auth_provider.dart';
import '../../dashboard/providers/dashboard_provider.dart';

// State class
class PharmacyState {
  final List<Medication> medications; // temporary list being built
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

  // Add a new empty medication (for manual entry)
  void addNewMedication() {
    final newMed = Medication(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: '',
      activeIngredient: '',
      dosage: '',
      time: DateTime.now(),
      frequency: 'daily',
    );
    state = state.copyWith(medications: [...state.medications, newMed]);
  }

  // Update a specific medication at index
  void updateMedication(int index, Medication updatedMed) {
    if (index < 0 || index >= state.medications.length) return;
    final updatedList = List<Medication>.from(state.medications);
    updatedList[index] = updatedMed;
    state = state.copyWith(medications: updatedList);
  }

  // Remove a medication at index
  void removeMedication(int index) {
    if (index < 0 || index >= state.medications.length) return;
    final updatedList = List<Medication>.from(state.medications);
    updatedList.removeAt(index);
    state = state.copyWith(medications: updatedList);
  }

  // Use real AI scan from Backend
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
          dosage: '', // critical for medical safety, the user must input this
          time: DateTime.now(),
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

  // Persist medications to DB
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

  // Clear all medications (after saving)
  void clearMedications() {
    state = const PharmacyState();
  }

  // Set loading state explicitly
  void setLoading(bool loading) {
    state = state.copyWith(isLoading: loading);
  }

  // Suggest Smart Schedule
  Future<List<Medication>?> suggestSchedule() async {
    if (_patientId == null || state.medications.isEmpty) return null;
    state = state.copyWith(isLoading: true);
    try {
      final response = await _pharmacyService.suggestSchedule(_patientId!, state.medications);
      final suggestionsRaw = response['suggestions'] as List<dynamic>;
      
      final List<Medication> optimizedMeds = suggestionsRaw.map((s) {
        final med = Medication.fromJson(s as Map<String, dynamic>);
        return med.copyWith(id: DateTime.now().microsecondsSinceEpoch.toString() + suggestionsRaw.indexOf(s).toString());
      }).toList();
      
      state = state.copyWith(isLoading: false);
      return optimizedMeds;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      rethrow;
    }
  }
}

// Provider
final pharmacyProvider = StateNotifierProvider<PharmacyNotifier, PharmacyState>((ref) {
  final pharmacyService = ref.watch(pharmacyServiceProvider);
  final authState = ref.watch(authProvider);
  return PharmacyNotifier(pharmacyService, authState.userId);
});
