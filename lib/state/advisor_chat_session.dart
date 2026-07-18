import 'package:flutter/foundation.dart';

import '../models/listing.dart';

class ChatMessage {
  final String text;
  final bool fromUser;
  final List<Listing> matches;

  const ChatMessage({required this.text, required this.fromUser, this.matches = const []});
}

/// Holds Land Advisor chat history in memory for the app's process lifetime,
/// so switching tabs doesn't lose it — only closing the app (or a hot
/// restart, which reinitializes this along with the rest of the app state)
/// resets the conversation.
class AdvisorChatSession extends ChangeNotifier {
  static const _greeting = ChatMessage(
    text: "Tell me your budget and category — I'll compare licensed listings for you.",
    fromUser: false,
  );

  final List<ChatMessage> messages = [_greeting];
  String? conversationId;

  void addMessage(ChatMessage message) {
    messages.add(message);
    notifyListeners();
  }
}
