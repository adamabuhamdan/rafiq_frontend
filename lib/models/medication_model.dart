import 'package:equatable/equatable.dart';
import 'package:intl/intl.dart';
import '../core/utils/number_util.dart';

class Medication extends Equatable {
  final String id;
  final String name;
  final String activeIngredient;
  final String dosage;

  /// All alarm times for this medication (internal Flutter representation).
  /// Stored as DateTime(0,0,0,h,m,s) for easy TimeOfDay conversion and sorting.
  final List<DateTime> times;

  final String frequency;
  final bool isPrimary;
  final List<String> weekdays;
  final String? aiInstruction;

  const Medication({
    required this.id,
    required this.name,
    required this.activeIngredient,
    required this.dosage,
    required this.times,
    required this.frequency,
    this.isPrimary = false,
    this.weekdays = const ["mon", "tue", "wed", "thu", "fri", "sat", "sun"],
    this.aiInstruction,
  });

  /// Backward-compat getter — first alarm time (used by nextDoseProvider, etc.)
  DateTime get time => times.isNotEmpty ? times.first : DateTime.now();

  // ── Deserialization ──────────────────────────────────────────────────────────
  factory Medication.fromJson(Map<String, dynamic> json) {
    // Parse times list from backend (strings like "08:00:00" or "08:00")
    final List<dynamic> rawTimes = json['times'] ?? [];
    final List<DateTime> parsedTimes = rawTimes.map((t) {
      final parts = t.toString().split(':');
      final h = int.tryParse(parts[0]) ?? 0;
      final m = parts.length > 1 ? (int.tryParse(parts[1]) ?? 0) : 0;
      final s = parts.length > 2 ? (int.tryParse(parts[2]) ?? 0) : 0;
      return DateTime(0, 0, 0, h, m, s);
    }).toList();

    // Fallback: if backend sends no times, default to now
    if (parsedTimes.isEmpty) {
      parsedTimes.add(DateTime.now());
    }

    return Medication(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      activeIngredient: json['active_ingredient'] ?? '',
      dosage: json['dosage_frequency'] ?? '',
      frequency: json['dosage_frequency'] ?? '',
      times: parsedTimes,
      isPrimary: json['is_primary'] ?? false,
      weekdays: List<String>.from(json['weekdays'] ?? []),
      aiInstruction: json['ai_instruction'],
    );
  }

  // ── Serialization ────────────────────────────────────────────────────────────
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'active_ingredient': activeIngredient,
      'dosage_frequency': NumberUtil.toEnglishNumbers(dosage),
      'weekdays': weekdays,
      // Convert each DateTime back to "HH:mm:ss" string for the backend
      'times': times.map((dt) => NumberUtil.toEnglishNumbers(DateFormat('HH:mm:ss').format(dt))).toList(),
      'is_primary': isPrimary,
      'ai_instruction': aiInstruction,
    };
  }

  // ── CopyWith ─────────────────────────────────────────────────────────────────
  Medication copyWith({
    String? id,
    String? name,
    String? activeIngredient,
    String? dosage,
    List<DateTime>? times,
    String? frequency,
    bool? isPrimary,
    List<String>? weekdays,
    String? aiInstruction,
  }) {
    return Medication(
      id: id ?? this.id,
      name: name ?? this.name,
      activeIngredient: activeIngredient ?? this.activeIngredient,
      dosage: dosage ?? this.dosage,
      times: times ?? this.times,
      frequency: frequency ?? this.frequency,
      isPrimary: isPrimary ?? this.isPrimary,
      weekdays: weekdays ?? this.weekdays,
      aiInstruction: aiInstruction ?? this.aiInstruction,
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        activeIngredient,
        dosage,
        times,
        frequency,
        isPrimary,
        weekdays,
        aiInstruction,
      ];
}
