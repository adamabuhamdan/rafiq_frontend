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
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
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
                  if (todayDoses.isEmpty) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  return _buildTimeline(context, todayDoses);
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

  // ── Chronological Timeline ─────────────────────────────────────────────────
  Widget _buildTimeline(BuildContext context, List<DoseEntry> doses) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: doses.length,
      itemBuilder: (context, index) {
        final dose = doses[index];
        final isLast = index == doses.length - 1;
        return _buildTimelineEntry(context, dose, isLast);
      },
    );
  }

  Widget _buildTimelineEntry(BuildContext context, DoseEntry dose, bool isLast) {
    final timeLabel = TimeOfDay(hour: dose.time.hour, minute: dose.time.minute)
        .format(context);
    final now = DateTime.now();
    final currentMinutes = now.hour * 60 + now.minute;
    final doseMinutes = dose.time.hour * 60 + dose.time.minute;
    final isPast = doseMinutes < currentMinutes;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Timeline spine ─────────────────────────────────────────────────
          SizedBox(
            width: 72,
            child: Column(
              children: [
                Text(
                  timeLabel,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: isPast ? Colors.grey.shade400 : AppColors.primary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 6),
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isPast ? Colors.grey.shade300 : AppColors.highlight,
                    border: Border.all(
                      color: isPast ? Colors.grey.shade300 : AppColors.highlight,
                      width: 2,
                    ),
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      color: Colors.grey.shade200,
                      margin: const EdgeInsets.symmetric(vertical: 4),
                    ),
                  ),
              ],
            ),
          ),

          const SizedBox(width: 12),

          // ── Dose card ──────────────────────────────────────────────────────
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 16),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border(
                    left: BorderSide(
                      color: isPast ? Colors.grey.shade200 : AppColors.highlight,
                      width: 3,
                    ),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: dose.medications.map((med) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _buildMedicationInDose(med, isPast),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMedicationInDose(Medication med, bool isPast) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isPast
                    ? Colors.grey.shade100
                    : AppColors.secondary.withOpacity(0.3),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.medication_liquid,
                color: isPast ? Colors.grey.shade400 : AppColors.primary,
                size: 18,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    med.name,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: isPast ? Colors.grey.shade500 : Colors.black87,
                    ),
                  ),
                  if (med.dosage.isNotEmpty)
                    Text(
                      med.dosage,
                      style: TextStyle(
                          fontSize: 13, color: Colors.grey.shade600),
                    ),
                ],
              ),
            ),
            if (isPast)
              Icon(Icons.check_circle, color: Colors.grey.shade300, size: 20),
          ],
        ),
        // AI Instruction chip
        if (med.aiInstruction != null && med.aiInstruction!.isNotEmpty) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.accent.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.accent.withOpacity(0.4)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.tips_and_updates_outlined,
                    size: 14, color: AppColors.highlight),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    med.aiInstruction!,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.primary.withOpacity(0.8),
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
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
