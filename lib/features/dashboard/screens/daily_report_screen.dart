import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../core/themes/app_theme.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/dashboard_provider.dart';
import '../../../models/patient_model.dart';
import '../../medical_record/providers/patient_provider.dart';
import '../../../core/utils/number_util.dart';

class DailyReportScreen extends ConsumerStatefulWidget {
  const DailyReportScreen({super.key});

  @override
  ConsumerState<DailyReportScreen> createState() => _DailyReportScreenState();
}

class _DailyReportScreenState extends ConsumerState<DailyReportScreen> {
  final _formKey = GlobalKey<FormState>();

  bool? _medsTaken;
  bool? _medsOnTime;

  final TextEditingController _sugarM = TextEditingController();
  final TextEditingController _sugarN = TextEditingController();
  final TextEditingController _sugarE = TextEditingController();

  final TextEditingController _bpMSys = TextEditingController();
  final TextEditingController _bpMDia = TextEditingController();
  final TextEditingController _bpESys = TextEditingController();
  final TextEditingController _bpEDia = TextEditingController();

  final TextEditingController _notes = TextEditingController();

  bool _isLoading = false;

  @override
  void dispose() {
    _sugarM.dispose();
    _sugarN.dispose();
    _sugarE.dispose();
    _bpMSys.dispose();
    _bpMDia.dispose();
    _bpESys.dispose();
    _bpEDia.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final authState = ref.read(authProvider);
    if (!authState.isAuthenticated || authState.userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(tr('daily_report.please_login'))),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final reqData = <String, dynamic>{
        'patient_id': authState.userId!,
        'language': context.locale.languageCode, 
      };

      if (_medsTaken != null) reqData['meds_taken'] = _medsTaken;
      if (_medsOnTime != null) reqData['meds_on_time'] = _medsOnTime;
      
      final patientState = ref.read(patientProvider);
      final diseases = patientState.patient?.diseases ?? [];
      final hasDiabetes = diseases.contains(DiseaseType.diabetes);
      final hasHypertension = diseases.contains(DiseaseType.hypertension);

      if (hasDiabetes) {
        if (_sugarM.text.isNotEmpty) reqData['sugar_morning'] = double.tryParse(NumberUtil.toEnglishNumbers(_sugarM.text));
        if (_sugarN.text.isNotEmpty) reqData['sugar_noon'] = double.tryParse(NumberUtil.toEnglishNumbers(_sugarN.text));
        if (_sugarE.text.isNotEmpty) reqData['sugar_evening'] = double.tryParse(NumberUtil.toEnglishNumbers(_sugarE.text));
      }

      if (hasHypertension) {
        if (_bpMSys.text.isNotEmpty) reqData['bp_morning_systolic'] = double.tryParse(NumberUtil.toEnglishNumbers(_bpMSys.text));
        if (_bpMDia.text.isNotEmpty) reqData['bp_morning_diastolic'] = double.tryParse(NumberUtil.toEnglishNumbers(_bpMDia.text));
        if (_bpESys.text.isNotEmpty) reqData['bp_evening_systolic'] = double.tryParse(NumberUtil.toEnglishNumbers(_bpESys.text));
        if (_bpEDia.text.isNotEmpty) reqData['bp_evening_diastolic'] = double.tryParse(NumberUtil.toEnglishNumbers(_bpEDia.text));
      }

      if (_notes.text.trim().isNotEmpty) reqData['notes'] = _notes.text.trim();

      final reportService = ref.read(reportServiceProvider);
      final response = await reportService.submitDailyReport(reqData);

      if (mounted) {
        setState(() => _isLoading = false);
        ref.invalidate(todayReportProvider); // <-- تحديث البيانات في لوحة التحكم
        _showAdviceDialog(response['advice'] ?? tr('daily_report.success'));
      }

    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${tr('daily_report.error')} $e')),
        );
      }
    }
  }

  void _showAdviceDialog(String advice) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(tr('daily_report.advice_title'), style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
        content: SingleChildScrollView(
          child: Text(advice, style: const TextStyle(height: 1.5)),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pop(context); // Go back to dashboard
            },
            child: Text(tr('daily_report.thanks')),
          )
        ],
      ),
    );
  }



  Widget _buildNumberField(String label, TextEditingController controller) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4.0),
        child: TextFormField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: label,
            fillColor: Colors.white,
            filled: true,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final patientState = ref.watch(patientProvider);
    final diseases = patientState.patient?.diseases ?? [];

    // Conditionally render based on patient diseases
    final hasDiabetes = diseases.contains(DiseaseType.diabetes);
    final hasHypertension = diseases.contains(DiseaseType.hypertension);

    return Scaffold(
      appBar: AppBar(
        title: Text(tr('daily_report.title'),
            style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.8)),
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.primary, AppColors.highlight],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
          ),
        ),
        foregroundColor: Colors.white,
      ),
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(20),
            physics: const BouncingScrollPhysics(),
            children: [
              Text(
                tr('daily_report.optional_hint'),
                style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 13,
                    fontWeight: FontWeight.w500),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),

              _buildSectionTitle(
                  tr('daily_report.routine_meds'), Icons.medication_rounded),
              _buildModernCard(
                color: AppColors.secondary.withOpacity(0.05),
                accentColor: AppColors.secondary,
                child: Column(
                  children: [
                    SwitchListTile(
                      title: Text(tr('daily_report.meds_taken'),
                          style: const TextStyle(
                              fontSize: 15, fontWeight: FontWeight.w600)),
                      value: _medsTaken ?? false,
                      activeColor: AppColors.highlight,
                      onChanged: (val) => setState(() => _medsTaken = val),
                    ),
                    if (_medsTaken == true)
                      SwitchListTile(
                        title: Text(tr('daily_report.meds_on_time'),
                            style: const TextStyle(fontSize: 15)),
                        value: _medsOnTime ?? false,
                        activeColor: AppColors.highlight,
                        onChanged: (val) => setState(() => _medsOnTime = val),
                      ),
                  ],
                ),
              ),

              if (hasDiabetes) ...[
                _buildSectionTitle(
                    tr('daily_report.sugar_readings'), Icons.water_drop_rounded),
                _buildModernCard(
                  color: Colors.orange.withOpacity(0.05),
                  accentColor: Colors.orange.shade100,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Row(
                      children: [
                        _buildNumberField(tr('daily_report.morning'), _sugarM),
                        _buildNumberField(tr('daily_report.noon'), _sugarN),
                        _buildNumberField(tr('daily_report.evening'), _sugarE),
                      ],
                    ),
                  ),
                ),
              ],

              if (hasHypertension) ...[
                _buildSectionTitle(
                    tr('daily_report.blood_pressure'), Icons.monitor_heart_rounded),
                _buildModernCard(
                  color: AppColors.highlight.withOpacity(0.05),
                  accentColor: AppColors.highlight.withOpacity(0.1),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(tr('daily_report.morning'),
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, color: Colors.black54)),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            _buildNumberField(tr('daily_report.systolic'), _bpMSys),
                            const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 8.0),
                              child: Text('/',
                                  style: TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.w300,
                                      color: Colors.black45)),
                            ),
                            _buildNumberField(tr('daily_report.diastolic'), _bpMDia),
                          ],
                        ),
                        const SizedBox(height: 20),
                        Text(tr('daily_report.evening'),
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, color: Colors.black54)),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            _buildNumberField(tr('daily_report.systolic'), _bpESys),
                            const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 8.0),
                              child: Text('/',
                                  style: TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.w300,
                                      color: Colors.black45)),
                            ),
                            _buildNumberField(tr('daily_report.diastolic'), _bpEDia),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],

              _buildSectionTitle(
                  tr('daily_report.additional_notes'), Icons.note_alt_rounded),
              Container(
                decoration: BoxDecoration(
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: TextFormField(
                  controller: _notes,
                  maxLines: 4,
                  decoration: InputDecoration(
                    hintText: tr('daily_report.notes_hint'),
                    hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.all(20),
                  ),
                ),
              ),

              const SizedBox(height: 40),

              _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(color: AppColors.highlight))
                  : Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        gradient: const LinearGradient(
                          colors: [AppColors.highlight, AppColors.secondary],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.highlight.withOpacity(0.3),
                            blurRadius: 15,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          foregroundColor: Colors.white,
                          shadowColor: Colors.transparent,
                          padding: const EdgeInsets.symmetric(vertical: 20),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20)),
                        ),
                        child: Text(tr('daily_report.submit'),
                            style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5)),
                      ),
                    ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModernCard({required Widget child, required Color color, required Color accentColor}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: [
          BoxShadow(
            color: accentColor.withOpacity(0.1),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.all(8),
      child: child,
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 24, 4, 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.highlight.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppColors.highlight, size: 24),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Text(title,
                style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary)),
          ),
        ],
      ),
    );
  }
}
