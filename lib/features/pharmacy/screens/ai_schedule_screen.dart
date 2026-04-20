import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../core/themes/app_theme.dart';
import '../../../models/medication_model.dart';

class AiScheduleScreen extends StatefulWidget {
  final List<Medication> medications;
  const AiScheduleScreen({super.key, required this.medications});

  @override
  State<AiScheduleScreen> createState() => _AiScheduleScreenState();
}

class _AiScheduleScreenState extends State<AiScheduleScreen> {
  late List<Medication> adjustedMeds;

  @override
  void initState() {
    super.initState();
    adjustedMeds = List.from(widget.medications);
  }

  void _saveAndReturn() {
    // In a real app, you would save to backend/database and then pop
    // For now, just show success and pop.
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(tr('pharmacy.saved_success'))),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isArabic = context.locale.languageCode == 'ar';

    return Scaffold(
      appBar: AppBar(
        title: Text(tr('pharmacy.edit_schedule')),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Premium AI Explanation Box
          Container(
            margin: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.accent.withOpacity(0.4),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.accent),
              boxShadow: [
                BoxShadow(color: AppColors.highlight.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 4)),
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
                        BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 8),
                      ],
                    ),
                    child: const CircleAvatar(
                      backgroundColor: AppColors.highlight,
                      radius: 20,
                      child: Icon(Icons.auto_awesome, color: Colors.white, size: 20),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 28, left: 20, right: 20, bottom: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tr('pharmacy.ai_explanation'),
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 18,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        isArabic
                            ? 'بناءً على تحليل حالتك الطبية وأوقات نومك واستيقاظك، قمت بتعديل مواعيد الأدوية لتتناسب مع روتينك اليومي ولتجنب التداخلات. يُرجى مراجعة الاقتراحات أدناه.'
                            : 'Based on your medical condition, wake/sleep times, and to avoid interactions, I have adjusted the medication times to fit your daily routine. Please review the suggestions below.',
                        style: const TextStyle(fontSize: 15, height: 1.5, color: Colors.black87),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: adjustedMeds.length,
              itemBuilder: (context, index) {
                final original = widget.medications[index];
                final adjusted = adjustedMeds[index];
                final timeChanged = original.time != adjusted.time;
                final freqChanged = original.frequency != adjusted.frequency;

                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border(left: BorderSide(color: (timeChanged || freqChanged) ? AppColors.highlight : Colors.transparent, width: 4)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.medication, color: AppColors.primary),
                            const SizedBox(width: 8),
                            Text(
                              adjusted.name,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _buildChangedRow(
                          label: tr('pharmacy.time'),
                          originalValue: _formatTime(original.time),
                          newValue: _formatTime(adjusted.time),
                          changed: timeChanged,
                        ),
                        const SizedBox(height: 12),
                        _buildChangedRow(
                          label: tr('pharmacy.daily_frequency'),
                          originalValue: original.frequency,
                          newValue: adjusted.frequency,
                          changed: freqChanged,
                        ),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: AppColors.background,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${tr('pharmacy.dosage')}: ${adjusted.dosage}',
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          SafeArea(
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, -5)),
                ],
                borderRadius: const BorderRadius.only(topLeft: Radius.circular(32), topRight: Radius.circular(32)),
              ),
              child: ElevatedButton(
                onPressed: _saveAndReturn,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  minimumSize: const Size(double.infinity, 56),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                ),
                child: Text(tr('pharmacy.save'), style: const TextStyle(fontSize: 20, color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChangedRow({
    required String label,
    required String originalValue,
    required String newValue,
    required bool changed,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontWeight: FontWeight.w500, color: Colors.grey.shade600, fontSize: 13)),
        const SizedBox(height: 4),
        if (changed)
          Row(
            children: [
              Text(
                originalValue,
                style: const TextStyle(
                  decoration: TextDecoration.lineThrough,
                  color: Colors.grey,
                  fontSize: 15,
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8.0),
                child: Icon(Icons.arrow_forward_rounded, color: AppColors.highlight, size: 18),
              ),
              Expanded(
                child: Text(
                  newValue,
                  style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
            ],
          )
        else
          Text(newValue, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
      ],
    );
  }

  String _formatTime(DateTime time) {
    return TimeOfDay.fromDateTime(time).format(context);
  }
}
