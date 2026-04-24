import 'package:equatable/equatable.dart';
import 'package:intl/intl.dart';

enum DiseaseType {
  diabetes,
  hypertension,
  thyroid,
}

class Patient extends Equatable {
  final String id;
  final String fullName;
  final DateTime dateOfBirth;
  final String gender; // 'male' or 'female'
  final String email;
  final List<DiseaseType> diseases;
  final String wakeTime; // Backend uses HH:mm:ss
  final String sleepTime; // Backend uses HH:mm:ss
  final String medicalDescription;
  final String? lastTestResults;
  final String? lastTestPdfUrl;

  const Patient({
    required this.id,
    required this.fullName,
    required this.dateOfBirth,
    required this.gender,
    required this.email,
    required this.diseases,
    required this.wakeTime,
    required this.sleepTime,
    required this.medicalDescription,
    this.lastTestResults,
    this.lastTestPdfUrl,
  });

  factory Patient.fromJson(Map<String, dynamic> json) {
    return Patient(
      id: json['id'] ?? '',
      fullName: json['full_name'] ?? '',
      dateOfBirth: DateTime.parse(json['date_of_birth'] ?? DateTime.now().toIso8601String()),
      gender: json['gender'] ?? 'male',
      email: json['email'] ?? '',
      diseases: (json['diseases'] as List?)
              ?.map((e) => DiseaseType.values.byName(e.toString().toLowerCase()))
              .toList() ??
          [],
      wakeTime: json['wake_time'] ?? '07:00:00',
      sleepTime: json['sleep_time'] ?? '22:00:00',
      medicalDescription: json['medical_description'] ?? '',
      lastTestResults: json['last_test_results'],
      lastTestPdfUrl: json['last_test_pdf_url'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'full_name': fullName,
      'date_of_birth': DateFormat('yyyy-MM-dd').format(dateOfBirth),
      'gender': gender,
      'email': email,
      'diseases': diseases.map((e) => e.name).toList(),
      'wake_time': wakeTime,
      'sleep_time': sleepTime,
      'medical_description': medicalDescription,
      'last_test_results': lastTestResults,
      'last_test_pdf_url': lastTestPdfUrl,
    };
  }

  Patient copyWith({
    String? id,
    String? fullName,
    DateTime? dateOfBirth,
    String? gender,
    String? email,
    List<DiseaseType>? diseases,
    String? wakeTime,
    String? sleepTime,
    String? medicalDescription,
    String? lastTestResults,
    String? lastTestPdfUrl,
  }) {
    return Patient(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      gender: gender ?? this.gender,
      email: email ?? this.email,
      diseases: diseases ?? this.diseases,
      wakeTime: wakeTime ?? this.wakeTime,
      sleepTime: sleepTime ?? this.sleepTime,
      medicalDescription: medicalDescription ?? this.medicalDescription,
      lastTestResults: lastTestResults ?? this.lastTestResults,
      lastTestPdfUrl: lastTestPdfUrl ?? this.lastTestPdfUrl,
    );
  }

  @override
  List<Object?> get props => [
        id,
        fullName,
        dateOfBirth,
        gender,
        email,
        diseases,
        wakeTime,
        sleepTime,
        medicalDescription,
        lastTestResults,
        lastTestPdfUrl,
      ];
}
