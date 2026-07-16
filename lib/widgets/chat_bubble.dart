import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// A single Land Advisor chat message: assistant bubbles show the "AI"
/// avatar and float left, user bubbles are filled nile-green and float right.
class ChatBubble extends StatelessWidget {
  final String text;
  final bool fromUser;

  const ChatBubble({super.key, required this.text, required this.fromUser});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: fromUser ? MainAxisAlignment.end : MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (!fromUser) ...[
          const CircleAvatar(
            radius: 13,
            backgroundColor: AppColors.nileGreen,
            child: Text('AI', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700)),
          ),
          const SizedBox(width: 8),
        ],
        Flexible(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
            constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
            decoration: BoxDecoration(
              color: fromUser ? AppColors.nileGreen : Colors.white,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Text(
              text,
              style: AppFonts.tajawal(size: 13, weight: FontWeight.w400, color: fromUser ? Colors.white : AppColors.ink, height: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}
