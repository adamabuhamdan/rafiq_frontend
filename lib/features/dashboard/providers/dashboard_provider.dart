import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/medication_model.dart';
import '../../../services/pharmacy_service.dart';
import '../../../services/report_service.dart';
import '../../../providers/network_provider.dart';
import '../../auth/providers/auth_provider.dart';

final pharmacyServiceProvider = Provider<PharmacyService>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return PharmacyService(apiClient);
});

final reportServiceProvider = Provider<ReportService>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return ReportService(apiClient);
});

// Real data from API
final dashboardMedicationsProvider = FutureProvider<List<Medication>>((ref) async {
  final authState = ref.watch(authProvider);
  if (!authState.isAuthenticated || authState.userId == null) return [];
  
  final pharmacyService = ref.watch(pharmacyServiceProvider);
  return await pharmacyService.getMedications(authState.userId!);
});

final nextDoseProvider = Provider<Medication?>((ref) {
  final medsAsync = ref.watch(dashboardMedicationsProvider);
  return medsAsync.when(
    data: (meds) => meds.isEmpty ? null : meds.first,
    loading: () => null,
    error: (_, __) => null,
  );
});

final todayMedicationsProvider = Provider<List<Medication>>((ref) {
  final medsAsync = ref.watch(dashboardMedicationsProvider);
  return medsAsync.when(
    data: (meds) => meds,
    loading: () => [],
    error: (_, __) => [],
  );
});


final patientNameProvider = FutureProvider<String>((ref) async {
  final authState = ref.watch(authProvider);
  if (!authState.isAuthenticated || authState.userId == null) return "Patient";

  final apiClient = ref.watch(apiClientProvider);
  try {
    final response = await apiClient.get('/patients/${authState.userId}');
    final fullName = response.data['full_name'] as String?;
    if (fullName != null && fullName.isNotEmpty) {
      return fullName.split(' ').first; // Return just the first name
    }
    return "Patient";
  } catch (e) {
    return "Patient";
  }
});

final todayReportProvider = FutureProvider<Map<String, dynamic>?>((ref) async {
  final authState = ref.watch(authProvider);
  if (!authState.isAuthenticated || authState.userId == null) return null;

  final reportService = ref.watch(reportServiceProvider);
  return await reportService.getTodayReport(authState.userId!);
});
