import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../core/themes/app_theme.dart';
import '../../../models/medication_model.dart';
import '../providers/dashboard_provider.dart';
import '../../chat/screens/chat_screen.dart';
import '../../pharmacy/screens/pharmacy_main_screen.dart';
import '../../settings/screens/setpage_screen.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'daily_report_screen.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  int _selectedIndex = 0;

  static const List<Widget> _screens = [
    DashboardContent(),
    ChatScreen(),
    PharmacyMainScreen(),
    SettingsScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(color: AppColors.background),
          _screens[_selectedIndex],
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          child: BottomNavigationBar(
            backgroundColor: AppColors.primary,
            currentIndex: _selectedIndex,
            onTap: _onItemTapped,
            type: BottomNavigationBarType.fixed,
            selectedItemColor: AppColors.secondary,
            unselectedItemColor: Colors.white70,
            showUnselectedLabels: false,
            elevation: 0,
            items: [
              BottomNavigationBarItem(
                icon: const Icon(Icons.dashboard_outlined),
                activeIcon: const Icon(Icons.dashboard),
                label: tr('dashboard.title'),
              ),
              BottomNavigationBarItem(
                icon: const Icon(Icons.chat_bubble_outline),
                activeIcon: const Icon(Icons.chat_bubble),
                label: tr('chat.title'),
              ),
              BottomNavigationBarItem(
                icon: const Icon(Icons.medical_services_outlined),
                activeIcon: const Icon(Icons.medical_services),
                label: tr('pharmacy.title'),
              ),
              BottomNavigationBarItem(
                icon: const Icon(Icons.settings_outlined),
                activeIcon: const Icon(Icons.settings),
                label: tr('settings.title'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────── DashboardContent ────────────────────────────

class DashboardContent extends ConsumerWidget {
  const DashboardContent({super.key});

  String _getGreeting(BuildContext context) {
    final hour = DateTime.now().hour;
    if (hour < 12) return tr('dashboard.good_morning');
    if (hour < 17) return tr('dashboard.good_afternoon');
    return tr('dashboard.good_evening');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nextDose = ref.watch(nextDoseProvider);
    final todayDoses = ref.watch(todayDosesProvider);
    final medsAsync = ref.watch(dashboardMedicationsProvider);
    final patientNameAsync = ref.watch(patientNameProvider);
    final todayReportAsync = ref.watch(todayReportProvider);
    final todayLogsAsync = ref.watch(todayLogsProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: AppColors.highlight.withOpacity(0.4),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: FloatingActionButton.extended(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const DailyReportScreen(),
              ),
            );
          },
          backgroundColor: AppColors.highlight,
          elevation: 0,
          icon: const Icon(Icons.assignment, color: Colors.white),
          label: Text(
            tr('daily_report.title'),
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
          ),
        ),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.primary,
          backgroundColor: Colors.white,
          onRefresh: () async {
            await Future.wait([
              ref.refresh(dashboardMedicationsProvider.future),
              ref.refresh(todayLogsProvider.future),
              ref.refresh(todayReportProvider.future),
              ref.refresh(patientNameProvider.future),
            ]);
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
              // ── Header ──────────────────────────────────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      patientNameAsync.when(
                        data: (name) => Text(
                          '${_getGreeting(context)}, $name',
                          style: const TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.5,
                          ),
                        ),
                        loading: () => const Text('Loading...',
                            style: TextStyle(
                                fontSize: 26, fontWeight: FontWeight.w800)),
                        error: (_, __) => Text(_getGreeting(context),
                            style: const TextStyle(
                                fontSize: 26, fontWeight: FontWeight.w800)),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        DateFormat('EEEE, MMM d, yyyy').format(DateTime.now()),
                        style: TextStyle(
                          fontSize: 15,
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.highlight, width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.highlight.withOpacity(0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const CircleAvatar(
                      backgroundColor: AppColors.primary,
                      radius: 26,
                      child: Icon(Icons.person_outline, color: Colors.white),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // ── Next Dose Card ───────────────────────────────────────────────
              medsAsync.when(
                data: (meds) => meds.isEmpty
                    ? _buildNoDoseCard(context)
                    : (nextDose != null
                        ? _buildNextDoseCard(context, nextDose)
                        : _buildNoDoseCard(context)),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (_, __) => _buildNoDoseCard(context),
              ),
              const SizedBox(height: 32),

              // ── Today's Chronological Timeline ───────────────────────────────
              Text(
                tr('dashboard.today_schedule'),
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),

              medsAsync.when(
                data: (meds) {
                  if (meds.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(
                          tr('dashboard.no_medications'),
                          style: TextStyle(
                              color: AppColors.primary.withOpacity(0.5),
                              fontWeight: FontWeight.w600),
                        ),
                      ),
                    );
                  }
                  // Return grouped medication cards directly instead of timeline doses
                  final takenDoses = todayLogsAsync.value ?? [];
                  return _buildMedicationsList(context, ref, meds, takenDoses);
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, _) => Text('Error: $err'),
              ),

              const SizedBox(height: 32),

              // ── AI Advice Card ────────────────────────────────────────────────
              todayReportAsync.when(
                data: (report) {
                  if (report != null && report['ai_advice'] != null) {
                    return _buildAiAdviceCard(report['ai_advice']);
                  }
                  return const SizedBox.shrink();
                },
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
              ),

              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
      ),
    );
  }

  // ── No Medications Card ────────────────────────────────────────────────────
  Widget _buildNoDoseCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4)),
        ],
      ),
      child: Center(
          child: Text(tr('dashboard.no_medications'),
              style: const TextStyle(fontWeight: FontWeight.w600))),
    );
  }

  // ── Next Dose Card (uses DoseEntry) ────────────────────────────────────────
  Widget _buildNextDoseCard(BuildContext context, DoseEntry nextDose) {
    final timeLabel = TimeOfDay(
            hour: nextDose.time.hour, minute: nextDose.time.minute)
        .format(context);
    final medNames = nextDose.medications.map((m) => m.name).join(' & ');

    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, Color(0xFF2C2C2C)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -20,
            top: -20,
            child: Icon(Icons.medical_information,
                size: 120, color: Colors.white.withOpacity(0.05)),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.alarm, color: Colors.white, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      tr('dashboard.next_dose'),
                      style: const TextStyle(
                          color: Colors.white70, fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Text(
                  medNames,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.5,
                  ),
                ),
                if (nextDose.medications.length == 1) ...[
                  const SizedBox(height: 6),
                  Text(
                    nextDose.medications.first.dosage,
                    style: const TextStyle(color: Colors.white70, fontSize: 15),
                  ),
                ],
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.highlight.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.access_time_filled,
                          color: Colors.white, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        timeLabel,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Medications List (Grouped Cards) ───────────────────────────────────────
  Widget _buildMedicationsList(BuildContext context, WidgetRef ref, List<Medication> meds, List<dynamic> takenDoses) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: meds.length,
      separatorBuilder: (context, index) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        return _buildMedicationCard(context, ref, meds[index], takenDoses);
      },
    );
  }

  Widget _buildMedicationCard(BuildContext context, WidgetRef ref, Medication med, List<dynamic> takenDoses) {
    final isArabic = context.locale.languageCode == 'ar';
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
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
            // ── Header: Med Icon + Name + Dosage
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.secondary.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.medication_liquid,
                    color: AppColors.primary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        med.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: Colors.black87,
                        ),
                      ),
                      if (med.dosage.isNotEmpty)
                        Text(
                          med.dosage,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // ── AI Advice Mini-card
            if (med.aiInstruction != null && med.aiInstruction!.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.accent.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.accent.withOpacity(0.4)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.tips_and_updates,
                        size: 18, color: AppColors.highlight),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        med.aiInstruction!,
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.primary.withOpacity(0.9),
                          height: 1.4,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            const Divider(),
            const SizedBox(height: 12),

            // ── Alarms Section
            Text(
              isArabic ? 'أوقات الجرعات' : 'Dose Times',
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 15,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: med.times.map((dt) {
                final timeLabel = TimeOfDay(hour: dt.hour, minute: dt.minute).format(context);
                final timeString = "${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}:00";

                final isTaken = takenDoses.any((log) => 
                  log['medication_id'] == med.id && 
                  log['scheduled_time'] != null && 
                  log['scheduled_time'].toString().contains(timeString)
                );

                final now = DateTime.now();
                final currentMinutes = now.hour * 60 + now.minute;
                final doseMinutes = dt.hour * 60 + dt.minute;
                
                final isMissed = doseMinutes < currentMinutes && !isTaken;

                return InkWell(
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: Text(isArabic ? 'تأكيد أخذ الجرعة' : 'Confirm Dose'),
                        content: Text(isArabic ? 'هل أنت متأكد من أخذ هذه الجرعة؟' : 'Confirm taking this dose?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: Text(isArabic ? 'إلغاء' : 'Cancel'),
                          ),
                          ElevatedButton(
                            onPressed: () async {
                              Navigator.pop(context); // Close dialog
                              final timeString = "${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}:00";
                              
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(isArabic ? 'جاري تسجيل الجرعة...' : 'Logging dose...')),
                              );

                              try {
                                final service = ref.read(pharmacyServiceProvider);
                                await service.logMedicationDose(med.id, timeString);
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(isArabic ? 'تم تسجيل الجرعة بنجاح' : 'Dose logged successfully!'),
                                      backgroundColor: Colors.green,
                                    ),
                                  );
                                }
                              } catch (e) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
                                  );
                                }
                              }
                            },
                            child: Text(isArabic ? 'تأكيد' : 'Confirm'),
                          ),
                        ],
                      ),
                    );
                  },
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: isTaken 
                          ? Colors.green.withOpacity(0.1) 
                          : isMissed 
                              ? Colors.red.withOpacity(0.1) 
                              : AppColors.highlight.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isTaken 
                            ? Colors.green.withOpacity(0.5) 
                            : isMissed 
                                ? Colors.red.withOpacity(0.5) 
                                : AppColors.highlight.withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isTaken ? Icons.check_circle : (isMissed ? Icons.warning : Icons.access_time),
                          size: 16,
                          color: isTaken ? Colors.green : (isMissed ? Colors.red : AppColors.highlight),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          timeLabel,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: isTaken ? Colors.green : (isMissed ? Colors.red : AppColors.primary),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  // ── AI Advice Card ────────────────────────────────────────────────────────
  Widget _buildAiAdviceCard(String advice) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.accent.withOpacity(0.2),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.accent.withOpacity(0.5)),
      ),
      padding: const EdgeInsets.all(24),
      margin: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.highlight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.psychology, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                tr('daily_report.advice_title'),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          MarkdownBody(
            data: advice,
            styleSheet: MarkdownStyleSheet(
              p: const TextStyle(fontSize: 15, height: 1.6, color: Colors.black87),
              listBullet:
                  const TextStyle(fontSize: 15, color: Colors.black87),
              strong: const TextStyle(
                  fontWeight: FontWeight.bold, color: AppColors.primary),
            ),
          ),
        ],
      ),
    );
  }
}
