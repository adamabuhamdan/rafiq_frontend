import 'package:equatable/equatable.dart';

enum SenderRole { user, assistant }

class ChatMessage extends Equatable {
  final String id;
  final String patientId;
  final SenderRole role;
  final String text;
  final String? agentUsed;
  final List<dynamic> sources;
  final DateTime timestamp;

  const ChatMessage({
    required this.id,
    required this.patientId,
    required this.role,
    required this.text,
    this.agentUsed,
    required this.sources,
    required this.timestamp,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'] ?? '',
      patientId: json['patient_id'] ?? '',
      role: json['role'] == 'user' ? SenderRole.user : SenderRole.assistant,
      text: json['content'] ?? '',
      agentUsed: json['agent_used'],
      sources: json['sources'] ?? [],
      timestamp: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
    );
  }

  @override
  List<Object?> get props => [id, patientId, role, text, agentUsed, sources, timestamp];
}
