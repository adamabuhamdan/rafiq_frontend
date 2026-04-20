import 'package:equatable/equatable.dart';

enum SenderRole { user, ai }

class ChatMessage extends Equatable {
  final String id;
  final String text;
  final SenderRole role;
  final DateTime timestamp;

  const ChatMessage({
    required this.id,
    required this.text,
    required this.role,
    required this.timestamp,
  });

  ChatMessage copyWith({
    String? id,
    String? text,
    SenderRole? role,
    DateTime? timestamp,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      text: text ?? this.text,
      role: role ?? this.role,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  @override
  List<Object?> get props => [id, text, role, timestamp];
}
