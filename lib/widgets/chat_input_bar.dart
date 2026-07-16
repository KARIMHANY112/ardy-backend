import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Pill text field + circular send button at the bottom of Land Advisor.
class ChatInputBar extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSend;

  const ChatInputBar({super.key, required this.controller, required this.onSend});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
      decoration: const BoxDecoration(color: Colors.white, border: Border(top: BorderSide(color: AppColors.divider))),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 44,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(color: AppColors.sandy, borderRadius: BorderRadius.circular(999)),
              child: TextField(
                controller: controller,
                onSubmitted: (_) => onSend(),
                style: AppFonts.tajawal(size: 13, weight: FontWeight.w400, color: AppColors.ink),
                decoration: InputDecoration(
                  hintText: 'Ask about a plot, price range…',
                  hintStyle: AppFonts.tajawal(size: 13, weight: FontWeight.w400, color: AppColors.inkAlpha(0.6)),
                  border: InputBorder.none,
                  isDense: true,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: onSend,
            child: Container(
              width: 44,
              height: 44,
              decoration: const BoxDecoration(color: AppColors.nileGreen, shape: BoxShape.circle),
              child: const Icon(Icons.arrow_forward, color: Colors.white, size: 18),
            ),
          ),
        ],
      ),
    );
  }
}
