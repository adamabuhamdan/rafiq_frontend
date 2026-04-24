import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:file_picker/file_picker.dart';
import '../../../core/themes/app_theme.dart';
import '../../../models/patient_model.dart';
import '../providers/patient_provider.dart';

import '../../dashboard/screens/dashboard_screen.dart';

class MedicalProfileScreen extends ConsumerStatefulWidget {
  final bool isOnboarding;

  const MedicalProfileScreen({super.key, this.isOnboarding = false});

  @override
  ConsumerState<MedicalProfileScreen> createState() =>
      _MedicalProfileScreenState();
}

class _MedicalProfileScreenState extends ConsumerState<MedicalProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _fullNameController;
  late TextEditingController _emailController;
  late TextEditingController _medicalDescController;
  late TextEditingController _testResultsController;
  late TextEditingController _familyEmailController;
  late TextEditingController _doctorEmailController;

  DateTime? _selectedDob;
  String? _selectedGender;
  String? _wakeTime; // HH:mm:ss
  String? _sleepTime; // HH:mm:ss
  List<DiseaseType> _selectedDiseases = [];
  bool _notificationsEnabled = true;
  bool _missedDoseAlert = true;
  bool _weeklyReport = true;
  String? _lastTestPdfUrl;

  @override
  void initState() {
    super.initState();
    _fullNameController = TextEditingController();
    _emailController = TextEditingController();
    _medicalDescController = TextEditingController();
    _testResultsController = TextEditingController();
    _familyEmailController = TextEditingController();
    _doctorEmailController = TextEditingController();
    _loadPatientData();
  }

  void _loadPatientData() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final patient = ref.read(patientProvider).patient;
      if (patient != null) {
        setState(() {
          _fullNameController.text = patient.fullName;
          _emailController.text = patient.email;
          _medicalDescController.text = patient.medicalDescription;
          _testResultsController.text = patient.lastTestResults ?? '';
          _selectedDob = patient.dateOfBirth;
          _selectedGender = patient.gender;
          _wakeTime = patient.wakeTime;
          _sleepTime = patient.sleepTime;
          _selectedDiseases = List.from(patient.diseases);
          _lastTestPdfUrl = patient.lastTestPdfUrl;
        });
      }
    });
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _medicalDescController.dispose();
    _testResultsController.dispose();
    _familyEmailController.dispose();
    _doctorEmailController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (_formKey.currentState!.validate()) {
      if (_selectedDob == null ||
          _selectedGender == null ||
          _wakeTime == null ||
          _sleepTime == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(tr('profile.fill_all_fields'))),
        );
        return;
      }

      final updatedPatient = Patient(
        id: ref.read(patientProvider).patient?.id ?? 'temp',
        fullName: _fullNameController.text.trim(),
        dateOfBirth: _selectedDob!,
        gender: _selectedGender!,
        email: _emailController.text.trim(),
        diseases: _selectedDiseases,
        wakeTime: _wakeTime!,
        sleepTime: _sleepTime!,
        medicalDescription: _medicalDescController.text.trim(),
        lastTestResults: _testResultsController.text.trim().isEmpty
            ? null
            : _testResultsController.text.trim(),
        lastTestPdfUrl: _lastTestPdfUrl,
      );

      final success =
          await ref.read(patientProvider.notifier).saveProfile(updatedPatient);
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(tr('profile.save_success'))),
        );
        if (widget.isOnboarding) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const DashboardScreen()),
          );
        } else {
          Navigator.pop(context);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(patientProvider);
    final isArabic = context.locale.languageCode == 'ar';

    return Scaffold(
      appBar: AppBar(
        title: Text(tr('profile.title'),
            style: const TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.highlight, AppColors.secondary],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.language),
            onPressed: () {
              if (context.locale.languageCode == 'ar') {
                context.setLocale(const Locale('en'));
              } else {
                context.setLocale(const Locale('ar'));
              }
            },
          ),
        ],
      ),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    // Avatar Header Profile
                    Center(
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const LinearGradient(
                            colors: [AppColors.secondary, AppColors.accent],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.secondary.withValues(alpha: 0.3),
                              blurRadius: 20,
                              spreadRadius: 2,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 4),
                          ),
                          child: const CircleAvatar(
                            radius: 46,
                            backgroundColor: Colors.transparent,
                            child: Icon(Icons.person,
                                size: 50, color: Colors.white),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      tr('settings.edit_medical_profile'),
                      style: const TextStyle(
                          fontSize: 22, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 32),

                    _buildSectionCard(
                      title: tr('profile.personal_info'),
                      icon: Icons.person_outline,
                      children: [
                        _buildTextField(
                          controller: _fullNameController,
                          label: tr('profile.full_name'),
                          validator: (v) =>
                              v!.isEmpty ? tr('profile.required') : null,
                        ),
                        const SizedBox(height: 12),
                        _buildDatePicker(),
                        const SizedBox(height: 12),
                        _buildGenderDropdown(),
                        const SizedBox(height: 12),
                        _buildTextField(
                          controller: _emailController,
                          label: tr('profile.email'),
                          keyboardType: TextInputType.emailAddress,
                          validator: (v) => v!.isEmpty || !v.contains('@')
                              ? tr('profile.valid_email')
                              : null,
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    _buildSectionCard(
                      title: tr('profile.medical_history'),
                      icon: Icons.history_edu,
                      children: [
                        _buildDiseaseChips(),
                        const SizedBox(height: 16),
                        _buildTextField(
                          controller: _medicalDescController,
                          label: tr('profile.medical_description'),
                          maxLines: 3,
                        ),
                        const SizedBox(height: 12),
                        _buildTextField(
                          controller: _testResultsController,
                          label: tr('profile.last_test_results'),
                          maxLines: 2,
                        ),
                        const SizedBox(height: 12),
                        _buildPdfUploadButton(),
                      ],
                    ),
                    const SizedBox(height: 24),
                    _buildSectionCard(
                      title: tr('profile.daily_routine'),
                      icon: Icons.wb_sunny_outlined,
                      children: [
                        _buildTimePicker(
                          label: tr('profile.wake_time'),
                          selectedTime: _wakeTime,
                          onChanged: (time) => setState(() => _wakeTime = time),
                        ),
                        const SizedBox(height: 12),
                        _buildTimePicker(
                          label: tr('profile.sleep_time'),
                          selectedTime: _sleepTime,
                          onChanged: (time) =>
                              setState(() => _sleepTime = time),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    _buildSectionCard(
                      title: tr('profile.emergency_monitoring'),
                      icon: Icons.health_and_safety_outlined,
                      children: [
                        _buildTextField(
                          controller: _familyEmailController,
                          label: tr('profile.family_email'),
                          keyboardType: TextInputType.emailAddress,
                        ),
                        const SizedBox(height: 12),
                        _buildTextField(
                          controller: _doctorEmailController,
                          label: tr('profile.doctor_email'),
                          keyboardType: TextInputType.emailAddress,
                        ),
                        const SizedBox(height: 12),
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(tr('profile.notifications_enabled'),
                              style: const TextStyle(fontSize: 18)),
                          value: _notificationsEnabled,
                          onChanged: (v) =>
                              setState(() => _notificationsEnabled = v),
                        ),
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(tr('profile.missed_dose_alert'),
                              style: const TextStyle(fontSize: 18)),
                          value: _missedDoseAlert,
                          onChanged: (v) =>
                              setState(() => _missedDoseAlert = v),
                        ),
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(tr('profile.weekly_report'),
                              style: const TextStyle(fontSize: 18)),
                          value: _weeklyReport,
                          onChanged: (v) => setState(() => _weeklyReport = v),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        gradient: const LinearGradient(
                          colors: [AppColors.highlight, AppColors.secondary],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.highlight.withValues(alpha: 0.3),
                            blurRadius: 15,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: _saveProfile,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          minimumSize: const Size(double.infinity, 56),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20)),
                        ),
                        child: Text(tr('profile.save'),
                            style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.white)),
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildSectionCard(
      {required String title,
      required IconData icon,
      required List<Widget> children}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.secondary, AppColors.accent],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.secondary.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(icon, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style:
                    const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ...children,
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(fontSize: 16, color: Colors.black54),
        fillColor: AppColors.background,
        filled: true,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      ),
      maxLines: maxLines,
      keyboardType: keyboardType,
      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
      validator: validator,
    );
  }

  Widget _buildDatePicker() {
    return GestureDetector(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: _selectedDob ??
              DateTime.now().subtract(const Duration(days: 365 * 30)),
          firstDate: DateTime(1900),
          lastDate: DateTime.now(),
        );
        if (picked != null) setState(() => _selectedDob = picked);
      },
      child: AbsorbPointer(
        child: TextFormField(
          decoration: InputDecoration(
            labelText: tr('profile.date_of_birth'),
            labelStyle: const TextStyle(fontSize: 18),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            suffixIcon: const Icon(Icons.calendar_today),
          ),
          controller: TextEditingController(
            text: _selectedDob != null
                ? DateFormat('yyyy-MM-dd').format(_selectedDob!)
                : '',
          ),
          style: const TextStyle(fontSize: 18),
          validator: (v) =>
              _selectedDob == null ? tr('profile.required') : null,
        ),
      ),
    );
  }

  Widget _buildGenderDropdown() {
    return DropdownButtonFormField<String>(
      value: _selectedGender,
      decoration: InputDecoration(
        labelText: tr('profile.gender'),
        labelStyle: const TextStyle(fontSize: 18),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      items: [
        DropdownMenuItem(
            value: 'male',
            child:
                Text(tr('profile.male'), style: const TextStyle(fontSize: 18))),
        DropdownMenuItem(
            value: 'female',
            child: Text(tr('profile.female'),
                style: const TextStyle(fontSize: 18))),
      ],
      onChanged: (v) => setState(() => _selectedGender = v),
      validator: (v) => v == null ? tr('profile.required') : null,
      style: const TextStyle(fontSize: 18, color: Colors.black),
    );
  }

  Widget _buildTimePicker(
      {required String label,
      required String? selectedTime,
      required Function(String) onChanged}) {
    return GestureDetector(
      onTap: () async {
        final initialTime = selectedTime != null
            ? TimeOfDay(
                hour: int.parse(selectedTime.split(':')[0]),
                minute: int.parse(selectedTime.split(':')[1]))
            : TimeOfDay.now();

        final picked = await showTimePicker(
          context: context,
          initialTime: initialTime,
        );
        if (picked != null) {
          final hour = picked.hour.toString().padLeft(2, '0');
          final minute = picked.minute.toString().padLeft(2, '0');
          onChanged('$hour:$minute:00');
        }
      },
      child: AbsorbPointer(
        child: TextFormField(
          decoration: InputDecoration(
            labelText: label,
            labelStyle: const TextStyle(fontSize: 18),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            suffixIcon: const Icon(Icons.access_time),
          ),
          controller: TextEditingController(
            text: selectedTime != null ? selectedTime.substring(0, 5) : '',
          ),
          style: const TextStyle(fontSize: 18),
          validator: (v) =>
              selectedTime == null ? tr('profile.required') : null,
        ),
      ),
    );
  }

  Widget _buildDiseaseChips() {
    final List<DiseaseType> allDiseases = [
      DiseaseType.diabetes,
      DiseaseType.hypertension,
      DiseaseType.thyroid
    ];
    return Wrap(
      spacing: 8,
      children: allDiseases.map((disease) {
        final isSelected = _selectedDiseases.contains(disease);
        return FilterChip(
          label: Text(tr('profile.${disease.name}'),
              style: const TextStyle(fontSize: 16)),
          selected: isSelected,
          onSelected: (selected) {
            setState(() {
              if (selected) {
                _selectedDiseases.add(disease);
              } else {
                _selectedDiseases.remove(disease);
              }
            });
          },
          backgroundColor: AppColors.background,
          selectedColor: AppColors.accent,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12), side: BorderSide.none),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          labelStyle: TextStyle(
              color: isSelected ? Colors.black : Colors.grey.shade800,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal),
        );
      }).toList(),
    );
  }

  Widget _buildPdfUploadButton() {
    return InkWell(
      onTap: () async {
        FilePickerResult? result = await FilePicker.pickFiles(
          type: FileType.custom,
          allowedExtensions: ['pdf'],
        );

        if (result != null) {
          setState(() {
            _lastTestPdfUrl = result.files.single.path;
          });
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.highlight.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child:
                  const Icon(Icons.picture_as_pdf, color: AppColors.highlight),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _lastTestPdfUrl != null
                    ? _lastTestPdfUrl!.split('/').last.split('\\').last
                    : tr('profile.upload_pdf'),
                style: const TextStyle(fontSize: 16, color: Colors.black54),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (_lastTestPdfUrl != null)
              IconButton(
                icon: const Icon(Icons.close, size: 20),
                onPressed: () {
                  setState(() {
                    _lastTestPdfUrl = null;
                  });
                },
              )
          ],
        ),
      ),
    );
  }
}
