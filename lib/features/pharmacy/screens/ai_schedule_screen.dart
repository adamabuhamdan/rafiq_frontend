import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../core/themes/app_theme.dart';
import '../../../models/medication_model.dart';
import '../providers/pharmacy_provider.dart';
import '../../dashboard/screens/dashboard_screen.dart';

class AiScheduleScreen extends ConsumerStatefulWidget {
  final List<Medication> medications;
  const AiScheduleScreen({super.key, required this.medications});

  @override
  ConsumerState<AiScheduleScreen> createState() => _AiScheduleScreenState();
}

class _AiScheduleScreenState extends ConsumerState<AiScheduleScreen> {
  late List<Medication> adjustedMeds;

  @override
  void initState() {
    super.initState();
    adjustedMeds = List.from(widget.medications);
  }

  // ── Alarm editing ──────────────────────────────────────────────────────────

  Future<void> _editAlarm(int medIndex, int alarmIndex) async {
    final current = adjustedMeds[medIndex].times[alarmIndex];
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: current.hour, minute: current.minute),
    );
    if (picked != null) {
      setState(() {
        final newTimes = List<DateTime>.from(adjustedMeds[medIndex].times);
        newTimes[alarmIndex] = DateTime(0, 0, 0, picked.hour, picked.minute);
        newTimes.sort((a, b) => a.hour != b.hour
            ? a.hour.compareTo(b.hour)
            : a.minute.compareTo(b.minute));
        adjustedMeds[medIndex] =
            adjustedMeds[medIndex].copyWith(times: newTimes);
      });
    }
  }

  void _deleteAlarm(int medIndex, int alarmIndex) {
    if (adjustedMeds[medIndex].times.length <= 1) return;
    setState(() {
      final newTimes = List<DateTime>.from(adjustedMeds[medIndex].times)
        ..removeAt(alarmIndex);
      adjustedMeds[medIndex] = adjustedMeds[medIndex].copyWith(times: newTimes);
    });
  }

  Future<void> _addAlarm(int medIndex) async {
    final picked =
        await showTimePicker(context: context, initialTime: TimeOfDay.now());
    if (picked != null) {
      setState(() {
        final newTimes = [
          ...adjustedMeds[medIndex].times,
          DateTime(0, 0, 0, picked.hour, picked.minute)
        ];
        newTimes.sort((a, b) => a.hour != b.hour
            ? a.hour.compareTo(b.hour)
            : a.minute.compareTo(b.minute));
        adjustedMeds[medIndex] =
            adjustedMeds[medIndex].copyWith(times: newTimes);
      });
    }
  }

  // ── Confirm & Save to DB ───────────────────────────────────────────────────

  Future<void> _confirmAndSave() async {
    final notifier = ref.read(pharmacyProvider.notifier);
    final isArabic = context.locale.languageCode == 'ar';

    try {
      // Save adjustedMeds directly — bypasses the provider state mismatch
      await notifier.replaceAndSave(adjustedMeds);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(
            isArabic
                ? 'تم حفظ الجدول بنجاح ✓'
                : 'Schedule saved successfully ✓',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          backgroundColor: AppColors.primary,
          behavior: SnackBarBehavior.floating,
        ));
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const DashboardScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(isArabic ? 'حدث خطأ أثناء الحفظ' : 'Error saving: $e'),
          backgroundColor: Colors.redAccent,
        ));
      }
    }
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isArabic = context.locale.languageCode == 'ar';
    final isSaving = ref.watch(pharmacyProvider).isLoading;

    return Scaffold(
      appBar: AppBar(
        title: Text(tr('pharmacy.edit_schedule')),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // AI explanation banner
          Container(
            margin: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.accent.withOpacity(0.4),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.accent),
              boxShadow: [
                BoxShadow(
                    color: AppColors.highlight.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4))
              ],
            ),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned(
                  top: -15,
                  left: isArabic ? null : 20,
                  right: isArabic ? 20 : null,
                  child: Container(
                    decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 8)
                        ]),
                    child: const CircleAvatar(
                        backgroundColor: AppColors.highlight,
                        radius: 20,
                        child: Icon(Icons.auto_awesome,
                            color: Colors.white, size: 20)),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(
                      top: 28, left: 20, right: 20, bottom: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(tr('pharmacy.ai_explanation'),
                          style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 18,
                              color: AppColors.primary)),
                      const SizedBox(height: 12),
                      Text(
                        isArabic
                            ? 'بناءً على حالتك الطبية وأوقات نومك، قمت بتوزيع مواعيد الأدوية لتناسب روتينك وتتجنب التداخلات. راجع المنبهات أدناه وعدّلها إن أردت.'
                            : 'Based on your medical history and sleep schedule, I\'ve distributed your medication times to fit your routine and avoid interactions. Review and adjust below.',
                        style: const TextStyle(
                            fontSize: 15, height: 1.5, color: Colors.black87),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Medication cards
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: adjustedMeds.length,
              itemBuilder: (context, medIndex) =>
                  _buildMedCard(context, medIndex, isArabic),
            ),
          ),

          // Confirm button
          SafeArea(
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 20,
                      offset: const Offset(0, -5))
                ],
                borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(32),
                    topRight: Radius.circular(32)),
              ),
              child: ElevatedButton.icon(
                onPressed: isSaving ? null : _confirmAndSave,
                icon: isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.check_circle_outline),
                label: Text(
                  isArabic ? 'تأكيد وحفظ الجدول' : 'Confirm & Save Schedule',
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 60),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20)),
                  elevation: 8,
                  shadowColor: AppColors.primary.withOpacity(0.4),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Medication card with alarm list ───────────────────────────────────────

  Widget _buildMedCard(BuildContext context, int medIndex, bool isArabic) {
    final med = adjustedMeds[medIndex];
    final original = widget.medications[medIndex];
    final timesChanged = med.times.length != original.times.length ||
        med.times.asMap().entries.any((e) => e.value != original.times[e.key]);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border(
            left: BorderSide(
                color: timesChanged ? AppColors.highlight : Colors.transparent,
                width: 4)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 4))
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Med name + dosage
            Row(
              children: [
                const Icon(Icons.medication, color: AppColors.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(med.name,
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold)),
                      if (med.dosage.isNotEmpty)
                        Text(med.dosage,
                            style: TextStyle(
                                fontSize: 13, color: Colors.grey.shade600)),
                    ],
                  ),
                ),
                if (timesChanged)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                        color: AppColors.highlight.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8)),
                    child: Text(isArabic ? 'معدَّل' : 'Modified',
                        style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.highlight,
                            fontWeight: FontWeight.bold)),
                  ),
              ],
            ),

            // AI instruction
            if (med.aiInstruction != null && med.aiInstruction!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.accent.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.accent.withOpacity(0.4)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.tips_and_updates_outlined,
                        size: 16, color: AppColors.highlight),
                    const SizedBox(width: 8),
                    Expanded(
                        child: Text(med.aiInstruction!,
                            style: TextStyle(
                                fontSize: 13,
                                color: AppColors.primary.withOpacity(0.85)))),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 8),

            // Alarm list header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                    isArabic
                        ? 'المنبهات (${med.times.length})'
                        : 'Alarms (${med.times.length})',
                    style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: AppColors.primary)),
              ],
            ),
            const SizedBox(height: 10),

            // Alarm rows
            ...List.generate(med.times.length, (alarmIndex) {
              final dt = med.times[alarmIndex];
              final label =
                  TimeOfDay(hour: dt.hour, minute: dt.minute).format(context);
              return _buildAlarmRow(medIndex, alarmIndex, label, isArabic,
                  canDelete: med.times.length > 1);
            }),

            // Add alarm
            TextButton.icon(
              onPressed: () => _addAlarm(medIndex),
              icon: const Icon(Icons.add_alarm, size: 18),
              label: Text(isArabic ? '+ إضافة منبه' : '+ Add Alarm'),
              style: TextButton.styleFrom(foregroundColor: AppColors.highlight),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAlarmRow(
      int medIndex, int alarmIndex, String label, bool isArabic,
      {required bool canDelete}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.secondary.withOpacity(0.5)),
      ),
      child: ListTile(
        dense: true,
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
              color: AppColors.highlight.withOpacity(0.15),
              shape: BoxShape.circle),
          child: const Icon(Icons.alarm, color: AppColors.highlight, size: 16),
        ),
        title: Text('${isArabic ? 'منبه' : 'Alarm'} ${alarmIndex + 1}',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
        subtitle: Text(label,
            style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: AppColors.primary)),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
                icon: const Icon(Icons.edit_outlined,
                    size: 18, color: AppColors.primary),
                onPressed: () => _editAlarm(medIndex, alarmIndex)),
            if (canDelete)
              IconButton(
                  icon: const Icon(Icons.delete_outline,
                      size: 18, color: Colors.redAccent),
                  onPressed: () => _deleteAlarm(medIndex, alarmIndex)),
          ],
        ),
        onTap: () => _editAlarm(medIndex, alarmIndex),
      ),
    );
  }
}
