import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/chat_model.dart';
import '../../../services/chat_service.dart';
import '../../../providers/network_provider.dart';
import '../../auth/providers/auth_provider.dart';

final chatServiceProvider = Provider<ChatService>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return ChatService(apiClient);
});

class ChatState {
  final List<ChatMessage> messages;
  final bool isLoading;

  const ChatState({this.messages = const [], this.isLoading = false});

  ChatState copyWith({List<ChatMessage>? messages, bool? isLoading}) {
    return ChatState(
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class ChatNotifier extends Notifier<ChatState> {
  ChatService get _chatService => ref.read(chatServiceProvider);
  String? get _patientId => ref.read(authProvider).userId;

  @override
  ChatState build() {
    final patientId = ref.watch(authProvider).userId;
    if (patientId != null) {
      Future.microtask(() => _loadHistory(patientId));
    }
    return const ChatState();
  }

  Future<void> _loadHistory(String patientId) async {
    state = state.copyWith(isLoading: true);
    try {
      final history = await _chatService.getHistory(patientId);
      state = state.copyWith(messages: history, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> sendMessage(
    String text, {
    String? imageBase64,
    String language = 'ar',
  }) async {
    final patientId = _patientId;
    if (patientId == null) return;

    // Optimistic UI update
    final userMsg = ChatMessage(
      id: DateTime.now().toIso8601String(),
      patientId: patientId,
      role: SenderRole.user,
      text: text,
      sources: const [],
      timestamp: DateTime.now(),
    );
    state = state.copyWith(
      messages: [...state.messages, userMsg],
      isLoading: true,
    );

    try {
      final response = await _chatService.sendMessage(
        patientId: patientId,
        message: text,
        imageBase64: imageBase64,
        language: language,
      );

      final aiMsg = ChatMessage(
        id: DateTime.now().toIso8601String(),
        patientId: patientId,
        role: SenderRole.assistant,
        text: response['reply'] ?? '',
        agentUsed: response['agent_used'],
        sources: response['sources'] ?? [],
        timestamp: DateTime.parse(
          response['timestamp'] ?? DateTime.now().toIso8601String(),
        ),
      );

      state = state.copyWith(
        messages: [...state.messages, aiMsg],
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false);
      // Optional: Add error message to chat or show snackbar
    }
  }
}

final chatProvider = NotifierProvider<ChatNotifier, ChatState>(
  ChatNotifier.new,
);
