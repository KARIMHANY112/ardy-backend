import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'ardi_wordmark.dart';

/// Compact screen header (wordmark + title [+ subtitle]) used on Favorites,
/// Post Listing, Land Advisor (dark variant), and Profile.
class BrandHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final bool dark;
  final double titleSize;

  const BrandHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.dark = false,
    this.titleSize = 20,
  });

  @override
  Widget build(BuildContext context) {
    final titleColor = dark ? Colors.white : AppColors.ink;
    final subtitleColor = dark ? Colors.white.withValues(alpha: 0.67) : AppColors.inkAlpha(0.6);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
      color: dark ? AppColors.deepGreen : Colors.white,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          ArdiWordmark(light: !dark, arabicSize: 15, latinSize: 7, letterSpacing: 2),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(title, style: AppFonts.cairo(size: titleSize, weight: FontWeight.w700, color: titleColor)),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(subtitle!, style: AppFonts.tajawal(size: 12, weight: FontWeight.w400, color: subtitleColor)),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
