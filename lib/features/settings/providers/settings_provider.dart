import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../services/report_service.dart';
import '../../../providers/network_provider.dart';
import '../../auth/providers/auth_provider.dart';

final settingsServiceProvider = Provider<SettingsService>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return SettingsService(apiClient);
});

// Settings state (matches backend SettingsUpdate schema)
class SettingsState {
  final String? familyEmail;
  final String? doctorEmail;
  final bool notificationsEnabled;
  final bool missedDoseAlertEnabled;
  final bool weeklyReportEnabled;
  final bool isLoading;
  final String? error;

  SettingsState({
    this.familyEmail,
    this.doctorEmail,
    this.notificationsEnabled = true,
    this.missedDoseAlertEnabled = true,
    this.weeklyReportEnabled = true,
    this.isLoading = false,
    this.error,
  });

  SettingsState copyWith({
    String? familyEmail,
    String? doctorEmail,
    bool? notificationsEnabled,
    bool? missedDoseAlertEnabled,
    bool? weeklyReportEnabled,
    bool? isLoading,
    String? error,
  }) {
    return SettingsState(
      familyEmail: familyEmail ?? this.familyEmail,
      doctorEmail: doctorEmail ?? this.doctorEmail,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      missedDoseAlertEnabled:
          missedDoseAlertEnabled ?? this.missedDoseAlertEnabled,
      weeklyReportEnabled: weeklyReportEnabled ?? this.weeklyReportEnabled,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }

  factory SettingsState.fromJson(Map<String, dynamic> json) {
    return SettingsState(
      familyEmail: json['family_email'],
      doctorEmail: json['doctor_email'],
      notificationsEnabled: json['notifications_enabled'] ?? true,
      missedDoseAlertEnabled: json['missed_dose_alert_enabled'] ?? true,
      weeklyReportEnabled: json['weekly_report_enabled'] ?? true,
    );
  }
}

class SettingsNotifier extends Notifier<SettingsState> {
  SettingsService get _settingsService => ref.read(settingsServiceProvider);
  String? get _patientId => ref.read(authProvider).userId;

  @override
  SettingsState build() {
    final patientId = ref.watch(authProvider).userId;
    if (patientId != null) {
      Future.microtask(() => _loadSettingsFor(patientId));
    }
    return SettingsState();
  }

  Future<void> _loadSettingsFor(String patientId) async {
    state = state.copyWith(isLoading: true);
    try {
      final json = await _settingsService.getSettings(patientId);
      state = SettingsState.fromJson(json).copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  // Load settings from backend
  Future<void> loadSettings() async {
    final patientId = _patientId;
    if (patientId == null) return;
    await _loadSettingsFor(patientId);
  }

  // Update a single setting
  Future<void> updateSetting({
    String? familyEmail,
    String? doctorEmail,
    bool? notificationsEnabled,
    bool? missedDoseAlertEnabled,
    bool? weeklyReportEnabled,
  }) async {
    final patientId = _patientId;
    if (patientId == null) return;

    final updateData = <String, dynamic>{};
    if (familyEmail != null) updateData['family_email'] = familyEmail;
    if (doctorEmail != null) updateData['doctor_email'] = doctorEmail;
    if (notificationsEnabled != null) {
      updateData['notifications_enabled'] = notificationsEnabled;
    }
    if (missedDoseAlertEnabled != null) {
      updateData['missed_dose_alert_enabled'] = missedDoseAlertEnabled;
    }
    if (weeklyReportEnabled != null) {
      updateData['weekly_report_enabled'] = weeklyReportEnabled;
    }

    state = state.copyWith(isLoading: true);
    try {
      final json = await _settingsService.updateSettings(patientId, updateData);
      state = SettingsState.fromJson(json).copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
}

final settingsProvider = NotifierProvider<SettingsNotifier, SettingsState>(
  SettingsNotifier.new,
);
