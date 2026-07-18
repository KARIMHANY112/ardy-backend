import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../services/advisor_repository.dart';
import '../../services/api_client.dart';
import '../../state/advisor_chat_session.dart';
import '../../widgets/app_bottom_nav.dart';
import '../../widgets/brand_header.dart';
import '../../widgets/chat_bubble.dart';
import '../../widgets/chat_input_bar.dart';
import '../../widgets/comparison_card.dart';
import '../../theme/app_dimens.dart';

/// Land Advisor (AI chat) — direction 1a: rounded-14 bubbles on sand bg,
/// inline comparison-card message type embedded in the chat thread.
class LandAdvisorScreen extends StatefulWidget {
  const LandAdvisorScreen({super.key});

  @override
  State<LandAdvisorScreen> createState() => _LandAdvisorScreenState();
}

class _LandAdvisorScreenState extends State<LandAdvisorScreen> {
  final _inputController = TextEditingController();
  final _scrollController = ScrollController();
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _scrollToEnd();
  }

  Future<void> _send() async {
    final text = _inputController.text.trim();
    if (text.isEmpty || _sending) return;

    final chat = context.read<AdvisorChatSession>();
    chat.addMessage(ChatMessage(text: text, fromUser: true));
    _inputController.clear();
    setState(() => _sending = true);
    _scrollToEnd();

    try {
      final response = await context.read<AdvisorRepository>().ask(text, conversationId: chat.conversationId);
      chat.conversationId = response.conversationId;
      chat.addMessage(ChatMessage(text: response.reply, fromUser: false, matches: response.matches));
    } on ApiException catch (e) {
      chat.addMessage(ChatMessage(text: "Couldn't reach the Land Advisor: ${e.message}", fromUser: false));
    } catch (_) {
      chat.addMessage(ChatMessage(text: "Couldn't reach the Land Advisor: no connection.", fromUser: false));
    } finally {
      if (mounted) setState(() => _sending = false);
      _scrollToEnd();
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
    final messages = context.watch<AdvisorChatSession>().messages;
    return AppBottomNavScaffold(
      currentIndex: 2,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const BrandHeader(title: 'Land Advisor', subtitle: 'AI assistant · compares listings for you', dark: true, titleSize: 18),
          Expanded(
            child: ListView.separated(
              controller: _scrollController,
              padding: const EdgeInsets.all(AppSpacing.s18),
              itemCount: messages.length + (_sending ? 1 : 0),
              separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.s12),
              itemBuilder: (context, index) {
                if (index == messages.length) {
                  return const ChatBubble(text: 'Thinking…', fromUser: false);
                }
                final message = messages[index];
                if (message.matches.isEmpty) {
                  return ChatBubble(text: message.text, fromUser: message.fromUser);
                }
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ChatBubble(text: message.text, fromUser: message.fromUser),
                    const SizedBox(height: AppSpacing.s8),
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
