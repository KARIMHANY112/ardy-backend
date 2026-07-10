import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../data/mock_listings.dart';
import '../../models/listing.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_bottom_nav.dart';

class _ChatMessage {
  final String text;
  final bool fromUser;
  final List<Listing> matches;

  _ChatMessage({required this.text, required this.fromUser, this.matches = const []});
}

class LandAdvisorScreen extends StatefulWidget {
  const LandAdvisorScreen({super.key});

  @override
  State<LandAdvisorScreen> createState() => _LandAdvisorScreenState();
}

class _LandAdvisorScreenState extends State<LandAdvisorScreen> {
  final _inputController = TextEditingController();
  final List<_ChatMessage> _messages = [
    _ChatMessage(
      text: "Hi! I'm the Land Advisor. Tell me your budget, category, and preferred location and I'll suggest matching listings.",
      fromUser: false,
    ),
  ];

  void _send() {
    final text = _inputController.text.trim();
    if (text.isEmpty) return;

    // Stub: POST /advisor/ask isn't wired up yet — this canned reply just
    // shows the comparison-card message type described in the design handoff.
    final matches = mockListings.take(2).toList();
    setState(() {
      _messages.add(_ChatMessage(text: text, fromUser: true));
      _messages.add(_ChatMessage(
        text: "Based on that, here's what I'd compare first:",
        fromUser: false,
        matches: matches,
      ));
      _inputController.clear();
    });
  }

  @override
  void dispose() {
    _inputController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppBottomNavScaffold(
      currentIndex: 2,
      title: 'Land Advisor',
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) => _MessageBubble(message: _messages[index]),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _inputController,
                    decoration: const InputDecoration(
                      hintText: 'Describe what you\'re looking for...',
                      isDense: true,
                    ),
                    onSubmitted: (_) => _send(),
                  ),
                ),
                const SizedBox(width: 8),
                CircleAvatar(
                  backgroundColor: AppColors.nileGreen,
                  child: IconButton(
                    icon: const Icon(Icons.send, color: Colors.white, size: 18),
                    onPressed: _send,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final _ChatMessage message;

  const _MessageBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final align = message.fromUser ? CrossAxisAlignment.end : CrossAxisAlignment.start;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: align,
        children: [
          Row(
            mainAxisAlignment: message.fromUser ? MainAxisAlignment.end : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (!message.fromUser) ...[
                const CircleAvatar(radius: 14, backgroundColor: AppColors.nileGreen, child: Text('AI', style: TextStyle(color: Colors.white, fontSize: 10))),
                const SizedBox(width: 8),
              ],
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: message.fromUser ? AppColors.nileGreen : Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: message.fromUser ? null : Border.all(color: AppColors.divider),
                  ),
                  child: Text(
                    message.text,
                    style: textTheme.bodyMedium?.copyWith(color: message.fromUser ? Colors.white : AppColors.ink),
                  ),
                ),
              ),
            ],
          ),
          if (message.matches.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.divider),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Comparing ${message.matches.length} listings', style: textTheme.bodyMedium?.copyWith(fontSize: 12, color: AppColors.ink.withValues(alpha: 0.6))),
                  const SizedBox(height: 8),
                  Row(
                    children: message.matches
                        .map((listing) => Expanded(
                              child: GestureDetector(
                                onTap: () => context.push('/listing/${listing.id}'),
                                child: Container(
                                  margin: const EdgeInsets.only(right: 8),
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: AppColors.sandy,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        height: 50,
                                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
                                        child: const Center(child: Icon(Icons.photo_outlined, size: 20, color: AppColors.divider)),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(listing.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: textTheme.bodyMedium?.copyWith(fontSize: 12, fontWeight: FontWeight.w600)),
                                      Text('${listing.price.toStringAsFixed(0)} EGP', style: textTheme.bodyMedium?.copyWith(fontSize: 12, color: AppColors.gold)),
                                    ],
                                  ),
                                ),
                              ),
                            ))
                        .toList(),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
