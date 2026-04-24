import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/medication_model.dart';
import '../../../services/pharmacy_service.dart';
import '../../../services/report_service.dart';
import '../../../providers/network_provider.dart';
import '../../auth/providers/auth_provider.dart';

// ── Service providers ─────────────────────────────────────────────────────────

final pharmacyServiceProvider = Provider<PharmacyService>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return PharmacyService(apiClient);
});

final reportServiceProvider = Provider<ReportService>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return ReportService(apiClient);
});

// ── Dose entry: one time slot that may contain multiple medications ────────────

class DoseEntry {
  /// Time of this dose (DateTime(0,0,0,h,m) for display purposes)
  final DateTime time;

  /// All medications due at this exact time slot
  final List<Medication> medications;

  const DoseEntry({required this.time, required this.medications});
}

// ── Data providers ────────────────────────────────────────────────────────────

/// Fetches all medications from the backend for the authenticated patient.
final dashboardMedicationsProvider = FutureProvider<List<Medication>>((
  ref,
) async {
  final authState = ref.watch(authProvider);
  if (!authState.isAuthenticated || authState.userId == null) return [];

  final pharmacyService = ref.watch(pharmacyServiceProvider);
  return await pharmacyService.getMedications(authState.userId!);
});

/// Fetches today's taken medication logs from the backend.
final todayLogsProvider = FutureProvider<List<dynamic>>((ref) async {
  final authState = ref.watch(authProvider);
  if (!authState.isAuthenticated || authState.userId == null) return [];

  final apiClient = ref.watch(apiClientProvider);
  try {
    final response = await apiClient.get(
      '/pharmacy/logs/today/${authState.userId}',
    );
    return response.data as List<dynamic>;
  } catch (e) {
    return [];
  }
});

/// Flattens all medications × their individual times into a chronological list.
/// Each DoseEntry groups all meds that share the same hour:minute.
final todayDosesProvider = Provider<List<DoseEntry>>((ref) {
  final medsAsync = ref.watch(dashboardMedicationsProvider);
  return medsAsync.when(
    data: (meds) {
      // Flatten: (time → list of meds)
      final Map<String, List<Medication>> grouped = {};

      for (final med in meds) {
        for (final t in med.times) {
          // Key by HH:mm to group medications at the same minute
          final key =
              '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
          grouped.putIfAbsent(key, () => []).add(med);
        }
      }

      // Build sorted DoseEntry list
      final entries = grouped.entries.map((e) {
        final parts = e.key.split(':');
        final time = DateTime(
          0,
          0,
          0,
          int.parse(parts[0]),
          int.parse(parts[1]),
        );
        return DoseEntry(time: time, medications: e.value);
      }).toList();

      entries.sort(
        (a, b) => a.time.hour != b.time.hour
            ? a.time.hour.compareTo(b.time.hour)
            : a.time.minute.compareTo(b.time.minute),
      );

      return entries;
    },
    loading: () => [],
    error: (_, __) => [],
  );
});

/// Returns the next upcoming DoseEntry based on current time.
final nextDoseProvider = Provider<DoseEntry?>((ref) {
  final doses = ref.watch(todayDosesProvider);
  if (doses.isEmpty) return null;

  final now = DateTime.now();
  final currentMinutes = now.hour * 60 + now.minute;

  // Find the first dose after current time
  for (final dose in doses) {
    final doseMinutes = dose.time.hour * 60 + dose.time.minute;
    if (doseMinutes > currentMinutes) return dose;
  }

  // All doses have passed — return the first one for tomorrow reference
  return doses.first;
});

// ── Legacy providers (kept for backward compat) ───────────────────────────────

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
      return fullName.split(' ').first;
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
