import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../models/listing.dart';
import '../../services/advisor_repository.dart';
import '../../services/api_client.dart';
import '../../widgets/app_bottom_nav.dart';
import '../../widgets/brand_header.dart';
import '../../widgets/chat_bubble.dart';
import '../../widgets/chat_input_bar.dart';
import '../../widgets/comparison_card.dart';

class _ChatMessage {
  final String text;
  final bool fromUser;
  final List<Listing> matches;

  _ChatMessage({required this.text, required this.fromUser, this.matches = const []});

  Map<String, dynamic> toJson() => {
        'text': text,
        'fromUser': fromUser,
        'matches': matches.map((m) => m.toJson()).toList(),
      };

  factory _ChatMessage.fromJson(Map<String, dynamic> json) => _ChatMessage(
        text: json['text'] as String,
        fromUser: json['fromUser'] as bool,
        matches: (json['matches'] as List<dynamic>).map((m) => Listing.fromJson(m as Map<String, dynamic>)).toList(),
      );
}

/// Land Advisor (AI chat) — direction 1a: rounded-14 bubbles on sand bg,
/// inline comparison-card message type embedded in the chat thread.
class LandAdvisorScreen extends StatefulWidget {
  const LandAdvisorScreen({super.key});

  @override
  State<LandAdvisorScreen> createState() => _LandAdvisorScreenState();
}

class _LandAdvisorScreenState extends State<LandAdvisorScreen> {
  static const _conversationIdKey = 'advisor_conversation_id';
  static const _messagesKey = 'advisor_messages';

  static final _greeting = _ChatMessage(
    text: "Tell me your budget and category — I'll compare licensed listings for you.",
    fromUser: false,
  );

  final _inputController = TextEditingController();
  final _scrollController = ScrollController();
  final List<_ChatMessage> _messages = [_greeting];
  String? _conversationId;
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _restoreHistory();
  }

  Future<void> _restoreHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final savedMessages = prefs.getString(_messagesKey);
    if (savedMessages == null) return;

    final decoded = (jsonDecode(savedMessages) as List<dynamic>)
        .map((m) => _ChatMessage.fromJson(m as Map<String, dynamic>))
        .toList();
    if (!mounted || decoded.isEmpty) return;

    setState(() {
      _messages
        ..clear()
        ..addAll(decoded);
      _conversationId = prefs.getString(_conversationIdKey);
    });
    _scrollToEnd();
  }

  Future<void> _persistHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_messagesKey, jsonEncode(_messages.map((m) => m.toJson()).toList()));
    if (_conversationId != null) await prefs.setString(_conversationIdKey, _conversationId!);
  }

  Future<void> _send() async {
    final text = _inputController.text.trim();
    if (text.isEmpty || _sending) return;

    setState(() {
      _messages.add(_ChatMessage(text: text, fromUser: true));
      _inputController.clear();
      _sending = true;
    });
    _scrollToEnd();

    try {
      final response = await context.read<AdvisorRepository>().ask(text, conversationId: _conversationId);
      _conversationId = response.conversationId;
      setState(() {
        _messages.add(_ChatMessage(text: response.reply, fromUser: false, matches: response.matches));
      });
    } on ApiException catch (e) {
      setState(() {
        _messages.add(_ChatMessage(text: "Couldn't reach the Land Advisor: ${e.message}", fromUser: false));
      });
    } catch (_) {
      setState(() {
        _messages.add(_ChatMessage(text: "Couldn't reach the Land Advisor: no connection.", fromUser: false));
      });
    } finally {
      if (mounted) setState(() => _sending = false);
      _scrollToEnd();
      await _persistHistory();
    }
  }

  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(_scrollController.position.maxScrollExtent, duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
    });
  }

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppBottomNavScaffold(
      currentIndex: 2,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const BrandHeader(title: 'Land Advisor', subtitle: 'AI assistant · compares listings for you', dark: true, titleSize: 18),
          Expanded(
            child: ListView.separated(
              controller: _scrollController,
              padding: const EdgeInsets.all(18),
              itemCount: _messages.length + (_sending ? 1 : 0),
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                if (index == _messages.length) {
                  return const ChatBubble(text: 'Thinking…', fromUser: false);
                }
                final message = _messages[index];
                if (message.matches.isEmpty) {
                  return ChatBubble(text: message.text, fromUser: message.fromUser);
                }
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ChatBubble(text: message.text, fromUser: message.fromUser),
                    const SizedBox(height: 8),
                    ComparisonCard(listings: message.matches),
                  ],
                );
              },
            ),
          ),
          ChatInputBar(controller: _inputController, onSend: _send),
        ],
      ),
    );
  }
}
