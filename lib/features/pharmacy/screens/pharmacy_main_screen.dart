import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/themes/app_theme.dart';
import '../providers/pharmacy_provider.dart';
import 'ai_schedule_screen.dart';
import '../../dashboard/screens/dashboard_screen.dart';

class PharmacyMainScreen extends ConsumerStatefulWidget {
  const PharmacyMainScreen({super.key});

  @override
  ConsumerState<PharmacyMainScreen> createState() => _PharmacyMainScreenState();
}

class _PharmacyMainScreenState extends ConsumerState<PharmacyMainScreen> {
  final List<TextEditingController> nameControllers = [];
  final List<TextEditingController> ingredientControllers = [];
  final List<TextEditingController> dosageControllers = [];
  final List<List<String>> weekdaysList = [];

  @override
  void didUpdateWidget(covariant PharmacyMainScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncControllers();
  }

  void _syncControllers() {
    final meds = ref.read(pharmacyProvider).medications;

    while (nameControllers.length < meds.length) {
      nameControllers.add(TextEditingController());
      ingredientControllers.add(TextEditingController());
      dosageControllers.add(TextEditingController());
      weekdaysList.add(['sun', 'mon', 'tue', 'wed', 'thu', 'fri', 'sat']);
    }
    while (nameControllers.length > meds.length) {
      nameControllers.removeLast();
      ingredientControllers.removeLast();
      dosageControllers.removeLast();
      weekdaysList.removeLast();
    }

    for (int i = 0; i < meds.length; i++) {
      if (nameControllers[i].text != meds[i].name) {
        nameControllers[i].text = meds[i].name;
      }
      if (ingredientControllers[i].text != meds[i].activeIngredient) {
        ingredientControllers[i].text = meds[i].activeIngredient;
      }
      if (dosageControllers[i].text != meds[i].dosage) {
        dosageControllers[i].text = meds[i].dosage;
      }
      if (meds[i].weekdays.isNotEmpty) {
        weekdaysList[i] = List.from(meds[i].weekdays);
      }
    }
  }

  void _updateMedicationFromForm(int index) {
    final med = ref.read(pharmacyProvider).medications[index];
    final updated = med.copyWith(
      name: nameControllers[index].text,
      activeIngredient: ingredientControllers[index].text,
      dosage: dosageControllers[index].text,
      weekdays: weekdaysList[index],
    );
    ref.read(pharmacyProvider.notifier).updateMedication(index, updated);
  }

  // ── Alarm time editing ─────────────────────────────────────────────────────

  Future<void> _editAlarm(
      BuildContext context, int medIndex, int alarmIndex) async {
    final med = ref.read(pharmacyProvider).medications[medIndex];
    final current = med.times[alarmIndex];
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: current.hour, minute: current.minute),
    );
    if (picked != null) {
      final newTimes = List<DateTime>.from(med.times);
      newTimes[alarmIndex] = DateTime(0, 0, 0, picked.hour, picked.minute);
      ref
          .read(pharmacyProvider.notifier)
          .updateMedicationTimes(medIndex, newTimes);
    }
  }

  void _deleteAlarm(int medIndex, int alarmIndex) {
    final med = ref.read(pharmacyProvider).medications[medIndex];
    if (med.times.length <= 1) return; // keep at least one
    final newTimes = List<DateTime>.from(med.times)..removeAt(alarmIndex);
    ref
        .read(pharmacyProvider.notifier)
        .updateMedicationTimes(medIndex, newTimes);
  }

  Future<void> _addAlarm(BuildContext context, int medIndex) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null) {
      final med = ref.read(pharmacyProvider).medications[medIndex];
      final newTimes = [
        ...med.times,
        DateTime(0, 0, 0, picked.hour, picked.minute)
      ];
      ref
          .read(pharmacyProvider.notifier)
          .updateMedicationTimes(medIndex, newTimes);
    }
  }

  // ── Image picker ───────────────────────────────────────────────────────────

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: source);
    if (pickedFile != null) {
      final bytes = await File(pickedFile.path).readAsBytes();
      await ref
          .read(pharmacyProvider.notifier)
          .scanPrescription(base64Encode(bytes));
    }
  }

  void _showImageSourcePicker(BuildContext context) {
    final isArabic = context.locale.languageCode == 'ar';
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      backgroundColor: Colors.white,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 50,
                height: 5,
                decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(10)),
              ),
              const SizedBox(height: 32),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                      color: AppColors.accent.withOpacity(0.3),
                      shape: BoxShape.circle),
                  child: const Icon(Icons.camera_alt, color: AppColors.primary),
                ),
                title: Text(tr('pharmacy.scan_camera'),
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 18)),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                },
              ),
              const SizedBox(height: 16),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                      color: AppColors.highlight.withOpacity(0.2),
                      shape: BoxShape.circle),
                  child: const Icon(Icons.photo_library,
                      color: AppColors.highlight),
                ),
                title: Text(
                    isArabic ? 'رفع من الاستوديو' : 'Upload from Gallery',
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 18)),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery);
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(pharmacyProvider);
    _syncControllers();
    final isArabic = context.locale.languageCode == 'ar';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(tr('pharmacy.title')),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Stack(
        children: [
          Column(
            children: [
              // Header actions
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 20,
                        offset: const Offset(0, 8))
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                        child: _buildHeaderAction(
                            icon: Icons.document_scanner_outlined,
                            label: tr('pharmacy.scan_camera'),
                            onTap: () => _showImageSourcePicker(context),
                            isHighlight: true)),
                    const SizedBox(width: 16),
                    Expanded(
                        child: _buildHeaderAction(
                            icon: Icons.edit_note,
                            label: isArabic ? 'إضافة يدوية' : 'Add Manually',
                            onTap: () => ref
                                .read(pharmacyProvider.notifier)
                                .addNewMedication(),
                            isHighlight: false)),
                  ],
                ),
              ),
              Expanded(
                child: state.medications.isEmpty
                    ? Center(
                        child: Text(
                            isArabic
                                ? 'لا توجد أدوية. أضف دواءك الأول.'
                                : 'No medications yet. Add your first one.',
                            style: TextStyle(
                                fontSize: 16,
                                color: AppColors.primary.withOpacity(0.5),
                                fontWeight: FontWeight.w500),
                            textAlign: TextAlign.center))
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        itemCount: state.medications.length,
                        itemBuilder: (context, index) =>
                            _buildMedicationCard(context, index, isArabic),
                      ),
              ),
            ],
          ),
          if (state.isLoading)
            Container(
                color: Colors.black54,
                child: const Center(child: CircularProgressIndicator())),
        ],
      ),
      bottomNavigationBar: state.medications.isEmpty
          ? null
          : _buildBottomActions(context, state),
    );
  }

  // ── Header action button ───────────────────────────────────────────────────

  Widget _buildHeaderAction(
      {required IconData icon,
      required String label,
      required VoidCallback onTap,
      required bool isHighlight}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 8),
        decoration: BoxDecoration(
          color: isHighlight
              ? AppColors.secondary.withOpacity(0.3)
              : AppColors.background,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: isHighlight ? AppColors.secondary : Colors.grey.shade200,
              width: 2),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isHighlight ? AppColors.secondary : Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  if (!isHighlight)
                    BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4))
                ],
              ),
              child: Icon(icon, size: 32, color: AppColors.primary),
            ),
            const SizedBox(height: 12),
            Text(label,
                style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: AppColors.primary),
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  // ── Medication card ────────────────────────────────────────────────────────

  Widget _buildMedicationCard(BuildContext context, int index, bool isArabic) {
    final med = ref.watch(pharmacyProvider).medications[index];

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 20,
              offset: const Offset(0, 8))
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Card header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
              decoration: const BoxDecoration(color: AppColors.secondary),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.8),
                          shape: BoxShape.circle),
                      child: const Icon(Icons.medication,
                          color: AppColors.primary, size: 20),
                    ),
                    const SizedBox(width: 16),
                    Text('${tr('pharmacy.medication')} ${index + 1}',
                        style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 18,
                            color: AppColors.primary)),
                  ]),
                  Container(
                    decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.5),
                        shape: BoxShape.circle),
                    child: IconButton(
                      icon: const Icon(Icons.delete_outline,
                          color: Colors.redAccent),
                      onPressed: () async {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20)),
                            title: Text(
                                isArabic ? 'تأكيد الحذف' : 'Confirm Delete',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold)),
                            content: Text(isArabic
                                ? 'هل أنت متأكد من حذف هذا الدواء؟'
                                : 'Delete this medication?'),
                            actions: [
                              TextButton(
                                  onPressed: () => Navigator.pop(ctx, false),
                                  child: Text(isArabic ? 'إلغاء' : 'Cancel',
                                      style:
                                          const TextStyle(color: Colors.grey))),
                              ElevatedButton(
                                onPressed: () => Navigator.pop(ctx, true),
                                style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.redAccent,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(12))),
                                child: Text(isArabic ? 'حذف' : 'Delete'),
                              ),
                            ],
                          ),
                        );
                        if (confirm == true) {
                          ref
                              .read(pharmacyProvider.notifier)
                              .removeMedication(index);
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildTextField(
                      controller: nameControllers[index],
                      label: tr('pharmacy.name'),
                      onChanged: (_) => _updateMedicationFromForm(index)),
                  const SizedBox(height: 16),
                  _buildTextField(
                      controller: ingredientControllers[index],
                      label: tr('pharmacy.active_ingredient'),
                      onChanged: (_) => _updateMedicationFromForm(index)),
                  const SizedBox(height: 16),
                  _buildTextField(
                      controller: dosageControllers[index],
                      label: tr('pharmacy.dosage'),
                      onChanged: (_) => _updateMedicationFromForm(index)),
                  const SizedBox(height: 24),

                  // ── AI Instruction banner ────────────────────────────────
                  if (med.aiInstruction != null &&
                      med.aiInstruction!.isNotEmpty) ...[
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.accent.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                            color: AppColors.accent.withOpacity(0.5)),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.tips_and_updates_outlined,
                              color: AppColors.highlight, size: 18),
                          const SizedBox(width: 10),
                          Expanded(
                              child: Text(med.aiInstruction!,
                                  style: TextStyle(
                                      fontSize: 13,
                                      color:
                                          AppColors.primary.withOpacity(0.85),
                                      height: 1.4))),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // ── Alarms section ───────────────────────────────────────
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(isArabic ? 'المنبهات' : 'Alarms',
                          style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                              color: AppColors.primary)),
                      Text(
                          '${med.times.length} ${isArabic ? 'منبه' : med.times.length == 1 ? 'alarm' : 'alarms'}',
                          style: TextStyle(
                              fontSize: 13, color: Colors.grey.shade500)),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Alarm rows
                  ...List.generate(med.times.length, (alarmIndex) {
                    final dt = med.times[alarmIndex];
                    final label = TimeOfDay(hour: dt.hour, minute: dt.minute)
                        .format(context);
                    return _buildAlarmRow(
                        context, index, alarmIndex, label, isArabic,
                        canDelete: med.times.length > 1);
                  }),

                  // Add alarm button
                  const SizedBox(height: 8),
                  TextButton.icon(
                    onPressed: () => _addAlarm(context, index),
                    icon: const Icon(Icons.add_alarm, size: 18),
                    label: Text(isArabic ? '+ إضافة منبه' : '+ Add Alarm'),
                    style: TextButton.styleFrom(
                        foregroundColor: AppColors.highlight),
                  ),

                  const SizedBox(height: 20),
                  Text(isArabic ? 'جدول الأيام' : 'Schedule Days',
                      style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                          color: AppColors.primary)),
                  const SizedBox(height: 16),
                  _buildDayPicker(index, isArabic),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAlarmRow(BuildContext context, int medIndex, int alarmIndex,
      String label, bool isArabic,
      {required bool canDelete}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.secondary.withOpacity(0.5)),
      ),
      child: ListTile(
        dense: true,
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
              color: AppColors.highlight.withOpacity(0.15),
              shape: BoxShape.circle),
          child: const Icon(Icons.alarm, color: AppColors.highlight, size: 18),
        ),
        title: Text(
          '${isArabic ? 'منبه' : 'Alarm'} ${alarmIndex + 1}',
          style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
        ),
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
              onPressed: () => _editAlarm(context, medIndex, alarmIndex),
              tooltip: isArabic ? 'تعديل' : 'Edit',
            ),
            if (canDelete)
              IconButton(
                icon: const Icon(Icons.delete_outline,
                    size: 18, color: Colors.redAccent),
                onPressed: () => _deleteAlarm(medIndex, alarmIndex),
                tooltip: isArabic ? 'حذف' : 'Delete',
              ),
          ],
        ),
        onTap: () => _editAlarm(context, medIndex, alarmIndex),
      ),
    );
  }

  Widget _buildDayPicker(int index, bool isArabic) {
    final daysList = isArabic
        ? ['ح', 'ن', 'ث', 'ر', 'خ', 'ج', 'س']
        : ['S', 'M', 'T', 'W', 'T', 'F', 'S'];
    final dbDays = ['sun', 'mon', 'tue', 'wed', 'thu', 'fri', 'sat'];
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(7, (dayIndex) {
        final dbDay = dbDays[dayIndex];
        final isSelected = weekdaysList[index].contains(dbDay);
        return GestureDetector(
          onTap: () {
            setState(() {
              if (isSelected) {
                weekdaysList[index].remove(dbDay);
              } else {
                weekdaysList[index].add(dbDay);
              }
            });
            _updateMedicationFromForm(index);
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: isSelected ? AppColors.highlight : Colors.transparent,
              shape: BoxShape.circle,
              border: Border.all(
                  color:
                      isSelected ? AppColors.highlight : Colors.grey.shade300,
                  width: 2),
            ),
            child: Center(
                child: Text(daysList[dayIndex],
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color:
                            isSelected ? Colors.white : Colors.grey.shade600))),
          ),
        );
      }),
    );
  }

  Widget _buildTextField(
      {required TextEditingController controller,
      required String label,
      required Function(String) onChanged}) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        labelStyle:
            TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.w500),
        fillColor: Colors.grey.shade50,
        filled: true,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: AppColors.primary, width: 2)),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      ),
      onChanged: onChanged,
    );
  }

  Widget _buildBottomActions(BuildContext context, PharmacyState state) {
    final isArabic = context.locale.languageCode == 'ar';
    return SafeArea(
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
              topLeft: Radius.circular(32), topRight: Radius.circular(32)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ElevatedButton.icon(
              onPressed: () async {
                await ref.read(pharmacyProvider.notifier).saveMedications();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text(
                        isArabic
                            ? 'تم حفظ الأدوية بنجاح'
                            : 'Medications saved successfully',
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    backgroundColor: AppColors.primary,
                    behavior: SnackBarBehavior.floating,
                  ));
                  Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const DashboardScreen()),
                      (r) => false);
                }
              },
              icon: const Icon(Icons.check_circle_outline),
              label: Text(tr('pharmacy.save'),
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.secondary.withOpacity(0.5),
                foregroundColor: AppColors.primary,
                minimumSize: const Size(double.infinity, 56),
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20)),
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: () async {
                try {
                  final optimizedMeds = await ref
                      .read(pharmacyProvider.notifier)
                      .suggestSchedule();
                  if (optimizedMeds != null && mounted) {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) =>
                                AiScheduleScreen(medications: optimizedMeds)));
                  }
                } catch (e, stacktrace) {
                  // 👈 التعديل الأول هنا
                  // 👈 التعديل الثاني: إضافة أسطر الطباعة هذه
                  print('🔴 AI Schedule Error: $e');
                  print('🔴 Stacktrace: $stacktrace');

                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text(isArabic
                          ? 'حدث خطأ: $e' // 👈 التعديل الثالث: عرض الخطأ على الشاشة بدلاً من النص العام
                          : 'Error connecting to AI: $e'),
                      backgroundColor: Colors.redAccent,
                    ));
                  }
                }
              },
              icon: const Icon(Icons.auto_awesome),
              label: Text(tr('pharmacy.ai_suggest'),
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 60),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20)),
                elevation: 8,
                shadowColor: AppColors.primary.withOpacity(0.5),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
