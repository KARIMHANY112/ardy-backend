import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// A single Land Advisor chat message: assistant bubbles show the "AI"
/// avatar and float left, user bubbles are filled nile-green and float right.
class ChatBubble extends StatelessWidget {
  final String text;
  final bool fromUser;

  const ChatBubble({super.key, required this.text, required this.fromUser});

  static final _boldPattern = RegExp(r'\*\*(.+?)\*\*');

  /// The advisor's replies use `**bold**` markdown; Text renders it literally,
  /// so split it into spans instead of pulling in a full markdown renderer.
  List<TextSpan> _spans(TextStyle style) {
    final spans = <TextSpan>[];
    var cursor = 0;
    for (final match in _boldPattern.allMatches(text)) {
      if (match.start > cursor) spans.add(TextSpan(text: text.substring(cursor, match.start)));
      spans.add(TextSpan(text: match.group(1), style: style.copyWith(fontWeight: FontWeight.w700)));
      cursor = match.end;
    }
    if (cursor < text.length) spans.add(TextSpan(text: text.substring(cursor)));
    return spans;
  }

  @override
  Widget build(BuildContext context) {
    final baseStyle = AppFonts.tajawal(size: 13, weight: FontWeight.w400, color: fromUser ? Colors.white : AppColors.ink, height: 1.5);
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
            child: RichText(text: TextSpan(style: baseStyle, children: _spans(baseStyle))),
          ),
        ),
      ],
    );
  }
}
