
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/message.dart';
import '../data/chat_service.dart';

class ChatState {
  final List<Message> messages;
  final bool isLoading;
  final String? error;

  ChatState({
    this.messages = const [],
    this.isLoading = false,
    this.error,
  });

  ChatState copyWith({
    List<Message>? messages,
    bool? isLoading,
    String? error,
  }) {
    return ChatState(
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

final chatControllerProvider = StateNotifierProvider<ChatController, ChatState>((ref) {
  final chatService = ref.watch(chatServiceProvider);
  return ChatController(chatService);
});

class ChatController extends StateNotifier<ChatState> {
  final ChatService _chatService;

  ChatController(this._chatService) : super(ChatState()) {
    // Add initial welcome message
    state = state.copyWith(messages: [
      Message(
        text: "Hello! I am JAL-X AI. How can I assist you with water safety today?",
        isUser: false,
        timestamp: DateTime.now(),
      ),
    ]);
  }

  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    // Add user message immediately
    final userMessage = Message(
      text: text,
      isUser: true,
      timestamp: DateTime.now(),
    );

    state = state.copyWith(
      messages: [...state.messages, userMessage],
      isLoading: true,
      error: null,
    );

    try {
      final reply = await _chatService.sendMessage(text);
      
      final aiMessage = Message(
        text: reply,
        isUser: false,
        timestamp: DateTime.now(),
      );

      state = state.copyWith(
        messages: [...state.messages, aiMessage],
        isLoading: false,
      );
    } catch (e) {
      print("DEBUG: ChatController error: $e"); // Added logging
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
        // Check if we should add an error message to the chat
         messages: [...state.messages, Message(
            text: "Sorry, I encountered an error. Please try again.",
            isUser: false,
            timestamp: DateTime.now(),
         )],
      );
    }
  }
}
