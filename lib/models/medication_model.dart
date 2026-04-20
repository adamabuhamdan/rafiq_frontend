import 'package:equatable/equatable.dart';
import 'package:intl/intl.dart';

class Medication extends Equatable {
  final String id;
  final String name;
  final String activeIngredient;
  final String dosage;
  final DateTime time; // current single time logic for UI simplicity
  final String frequency; // daily, twice daily etc. (Can be phased out later)
  final bool isPrimary;
  final List<String> weekdays; // e.g. ["mon", "tue"]

  // 1. إضافة حقل تعليمات الذكاء الاصطناعي (مسموح أن يكون فارغاً Null)
  final String? aiInstruction;

  const Medication({
    required this.id,
    required this.name,
    required this.activeIngredient,
    required this.dosage,
    required this.time,
    required this.frequency,
    this.isPrimary = false,
    this.weekdays = const ["mon", "tue", "wed", "thu", "fri", "sat", "sun"],
    this.aiInstruction, // 2. إضافته هنا
  });

  factory Medication.fromJson(Map<String, dynamic> json) {
    // Handling backend "times" list by picking first for UI model
    final List<dynamic> timesList = json['times'] ?? [];
    DateTime parsedTime = DateTime.now();
    if (timesList.isNotEmpty) {
      final String firstTime = timesList.first.toString();
      final parts = firstTime.split(':');
      parsedTime = DateTime(0, 0, 0, int.parse(parts[0]), int.parse(parts[1]));
    }

    return Medication(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      activeIngredient: json['active_ingredient'] ?? '',
      dosage: json['dosage_frequency'] ?? '',
      frequency: json['dosage_frequency'] ?? '',
      time: parsedTime,
      isPrimary: json['is_primary'] ?? false,
      weekdays: List<String>.from(json['weekdays'] ?? []),
      aiInstruction: json['ai_instruction'], // 3. قراءة النصيحة من الباك-إند
    );
  }

  Map<String, dynamic> toJson() {
    return {
      // إرسال الـ ID مهم جداً للباك-إند ليعرف أي دواء يقوم بتحديثه (UPSERT)
      'id': id,
      'name': name,
      'active_ingredient': activeIngredient,
      'dosage_frequency': dosage, // 4. الاعتماد على النص الحر الذي يكتبه المريض
      'weekdays': weekdays,
      'times': [DateFormat('HH:mm:ss').format(time)],
      'is_primary': isPrimary,
      'ai_instruction':
          aiInstruction, // إرسالها مرة أخرى كي لا تضيع عند التحديث
    };
  }

  Medication copyWith({
    String? id,
    String? name,
    String? activeIngredient,
    String? dosage,
    DateTime? time,
    String? frequency,
    bool? isPrimary,
    List<String>? weekdays,
    String? aiInstruction, // 5. التحديث هنا
  }) {
    return Medication(
      id: id ?? this.id,
      name: name ?? this.name,
      activeIngredient: activeIngredient ?? this.activeIngredient,
      dosage: dosage ?? this.dosage,
      time: time ?? this.time,
      frequency: frequency ?? this.frequency,
      isPrimary: isPrimary ?? this.isPrimary,
      weekdays: weekdays ?? this.weekdays,
      aiInstruction:
          aiInstruction ?? this.aiInstruction, // تمرير القيمة الجديدة
    );
  }

  @override
  // 6. إضافة الحقل للمقارنة
  List<Object?> get props => [
        id,
        name,
        activeIngredient,
        dosage,
        time,
        frequency,
        isPrimary,
        weekdays,
        aiInstruction
      ];
}
