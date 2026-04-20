import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/chat_model.dart';
import '../../../services/chat_service.dart';
import '../../../providers/network_provider.dart';
import '../../auth/providers/auth_provider.dart';

final chatServiceProvider = Provider<ChatService>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return ChatService(apiClient);
});

final chatProvider = StateNotifierProvider<ChatNotifier, ChatState>((ref) {
  final chatService = ref.watch(chatServiceProvider);
  final authState = ref.watch(authProvider);
  return ChatNotifier(chatService, authState.userId);
});

class ChatState {
  final List<ChatMessage> messages;
  final bool isLoading;

  const ChatState({
    this.messages = const [],
    this.isLoading = false,
  });

  ChatState copyWith({
    List<ChatMessage>? messages,
    bool? isLoading,
  }) {
    return ChatState(
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class ChatNotifier extends StateNotifier<ChatState> {
  final ChatService _chatService;
  final String? _patientId;

  ChatNotifier(this._chatService, this._patientId) : super(const ChatState()) {
    if (_patientId != null) {
      _loadHistory();
    }
  }

  Future<void> _loadHistory() async {
    state = state.copyWith(isLoading: true);
    try {
      final history = await _chatService.getHistory(_patientId!);
      state = state.copyWith(messages: history, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> sendMessage(String text, {String? imageBase64, String language = 'ar'}) async {
    if (_patientId == null) return;

    // Optimistic UI update
    final userMsg = ChatMessage(
      id: DateTime.now().toIso8601String(),
      patientId: _patientId!,
      role: SenderRole.user,
      text: text,
      sources: const [],
      timestamp: DateTime.now(),
    );
    state = state.copyWith(messages: [...state.messages, userMsg], isLoading: true);

    try {
      final response = await _chatService.sendMessage(
        patientId: _patientId!,
        message: text,
        imageBase64: imageBase64,
        language: language,
      );

      final aiMsg = ChatMessage(
        id: DateTime.now().toIso8601String(),
        patientId: _patientId!,
        role: SenderRole.assistant,
        text: response['reply'] ?? '',
        agentUsed: response['agent_used'],
        sources: response['sources'] ?? [],
        timestamp: DateTime.parse(response['timestamp'] ?? DateTime.now().toIso8601String()),
      );

      state = state.copyWith(messages: [...state.messages, aiMsg], isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false);
      // Optional: Add error message to chat or show snackbar
    }
  }
}
