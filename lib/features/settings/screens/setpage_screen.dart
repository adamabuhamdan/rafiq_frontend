import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../core/themes/app_theme.dart';
import '../providers/settings_provider.dart';
import '../../medical_record/screens/medical_record_screen.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final TextEditingController _familyEmailController = TextEditingController();
  final TextEditingController _doctorEmailController = TextEditingController();

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(settingsProvider.notifier).loadSettings();
    });
  }

  @override
  void dispose() {
    _familyEmailController.dispose();
    _doctorEmailController.dispose();
    super.dispose();
  }

  // تحديث الإيميلات عند تغييرها
  void _updateEmails() {
    final familyEmail = _familyEmailController.text.trim();
    final doctorEmail = _doctorEmailController.text.trim();
    if (familyEmail.isNotEmpty || doctorEmail.isNotEmpty) {
      ref.read(settingsProvider.notifier).updateSetting(
            familyEmail: familyEmail.isEmpty ? null : familyEmail,
            doctorEmail: doctorEmail.isEmpty ? null : doctorEmail,
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    final settingsState = ref.watch(settingsProvider);
    final isArabic = context.locale.languageCode == 'ar';
    const userEmail = "ahmed@example.com"; // TODO: get from auth

    // مزامنة القيم المحملة مع الـ Controllers
    if (settingsState.familyEmail != _familyEmailController.text &&
        settingsState.familyEmail != null) {
      _familyEmailController.text = settingsState.familyEmail!;
    }
    if (settingsState.doctorEmail != _doctorEmailController.text &&
        settingsState.doctorEmail != null) {
      _doctorEmailController.text = settingsState.doctorEmail!;
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(tr('settings.title')),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: settingsState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: Column(
                children: [
                  // Notification Settings Section
                  _buildSectionCard(
                    title: tr('settings.notifications'),
                    children: [
                      _buildSwitchTile(
                        title: tr('settings.general_notifications'),
                        value: settingsState.notificationsEnabled,
                        icon: Icons.notifications_active_outlined,
                        iconColor: AppColors.highlight,
                        onChanged: (val) {
                          ref.read(settingsProvider.notifier).updateSetting(
                                notificationsEnabled: val,
                              );
                        },
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 24),
                        child: Divider(height: 1, color: Colors.black12),
                      ),
                      _buildSwitchTile(
                        title: tr('settings.missed_dose_alerts'),
                        subtitle: tr('settings.missed_dose_subtitle'),
                        value: settingsState.missedDoseAlertEnabled,
                        icon: Icons.alarm_off,
                        iconColor: Colors.redAccent,
                        onChanged: (val) {
                          ref.read(settingsProvider.notifier).updateSetting(
                                missedDoseAlertEnabled: val,
                              );
                        },
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 24),
                        child: Divider(height: 1, color: Colors.black12),
                      ),
                      _buildSwitchTile(
                        title: tr('settings.weekly_reports'),
                        subtitle: tr('settings.weekly_reports_subtitle'),
                        value: settingsState.weeklyReportEnabled,
                        icon: Icons.assessment_outlined,
                        iconColor: AppColors.primary,
                        onChanged: (val) {
                          ref.read(settingsProvider.notifier).updateSetting(
                                weeklyReportEnabled: val,
                              );
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Account & Privacy Section
                  _buildSectionCard(
                    title: tr('settings.account'),
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: AppColors.secondary.withOpacity(0.3),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(Icons.email_outlined, color: AppColors.primary),
                            ),
                            const SizedBox(width: 16),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(tr('settings.logged_in_as'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                const SizedBox(height: 4),
                                Text(userEmail, style: TextStyle(color: Colors.grey.shade600)),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: TextFormField(
                          controller: _familyEmailController,
                          decoration: InputDecoration(
                            labelText: tr('settings.family_email'),
                            hintText: tr('settings.family_email_hint'),
                            fillColor: AppColors.background,
                            filled: true,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide.none,
                            ),
                            prefixIcon: const Icon(Icons.family_restroom),
                          ),
                          keyboardType: TextInputType.emailAddress,
                          onChanged: (_) => _updateEmails(),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: TextFormField(
                          controller: _doctorEmailController,
                          decoration: InputDecoration(
                            labelText: tr('settings.doctor_email'),
                            hintText: tr('settings.doctor_email_hint'),
                            fillColor: AppColors.background,
                            filled: true,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide.none,
                            ),
                            prefixIcon: const Icon(Icons.local_hospital),
                          ),
                          keyboardType: TextInputType.emailAddress,
                          onChanged: (_) => _updateEmails(),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const MedicalProfileScreen()),
                            );
                          },
                          icon: const Icon(Icons.edit_document),
                          label: Text(tr('settings.edit_medical_profile'), style: const TextStyle(fontWeight: FontWeight.bold)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.accent,
                            foregroundColor: AppColors.primary,
                            minimumSize: const Size(double.infinity, 56),
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // App Info Section
                  _buildSectionCard(
                    title: tr('settings.app_info'),
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: AppColors.secondary.withOpacity(0.3),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(Icons.language, color: AppColors.primary),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Text(tr('settings.language'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              decoration: BoxDecoration(
                                color: AppColors.background,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  value: isArabic ? 'ar' : 'en',
                                  icon: const Icon(Icons.keyboard_arrow_down, color: AppColors.primary),
                                  items: const [
                                    DropdownMenuItem(value: 'en', child: Text('English', style: TextStyle(fontWeight: FontWeight.bold))),
                                    DropdownMenuItem(value: 'ar', child: Text('العربية', style: TextStyle(fontWeight: FontWeight.bold))),
                                  ],
                                  onChanged: (value) {
                                    if (value != null) {
                                      context.setLocale(Locale(value));
                                    }
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: ElevatedButton.icon(
                          onPressed: () {
                            _showLogoutDialog(context);
                          },
                          icon: const Icon(Icons.logout),
                          label: Text(tr('settings.logout'), style: const TextStyle(fontWeight: FontWeight.bold)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red.shade50,
                            foregroundColor: Colors.red.shade700,
                            minimumSize: const Size(double.infinity, 56),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                              side: BorderSide(color: Colors.red.shade200, width: 1.5),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
    );
  }

  Widget _buildSectionCard(
      {required String title, required List<Widget> children}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
            child: Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primary, letterSpacing: -0.5),
            ),
          ),
          ...children,
        ],
      ),
    );
  }

  Widget _buildSwitchTile({
    required String title,
    String? subtitle,
    required bool value,
    required IconData icon,
    required Color iconColor,
    required Function(bool) onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: SwitchListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16),
        secondary: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.15),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: iconColor),
        ),
        title: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        subtitle: subtitle != null
            ? Text(subtitle, style: TextStyle(fontSize: 13, color: Colors.grey.shade600))
            : null,
        value: value,
        onChanged: onChanged,
        activeColor: AppColors.primary,
        activeTrackColor: AppColors.primary.withOpacity(0.4),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(tr('settings.logout_confirm_title')),
        content: Text(tr('settings.logout_confirm_message')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(tr('settings.cancel')),
          ),
          TextButton(
            onPressed: () {
              // TODO: Clear auth token and navigate to login
              Navigator.pop(ctx);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(tr('settings.logout')),
          ),
        ],
      ),
    );
  }
}
