import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// The small inline "ارضي / A R D I" lockup used in screen headers
/// (Home, Favorites, Post Listing, Land Advisor).
///
/// [light] picks the ink color for the surface it sits on: true = green
/// wordmark for white/sandy headers, false = white wordmark for the
/// deep-green Land Advisor header.
class ArdiWordmark extends StatelessWidget {
  final bool light;
  final double arabicSize;
  final double latinSize;
  final double letterSpacing;

  const ArdiWordmark({
    super.key,
    this.light = true,
    this.arabicSize = 19,
    this.latinSize = 9,
    this.letterSpacing = 2.5,
  });

  @override
  Widget build(BuildContext context) {
    final wordmarkColor = light ? AppColors.deepGreen : Colors.white;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'ارضي',
          textDirection: TextDirection.rtl,
          style: AppFonts.cairo(size: arabicSize, weight: FontWeight.w700, color: wordmarkColor, height: 1),
        ),
        Text(
          'A R D I',
          style: AppFonts.tajawal(
            size: latinSize,
            weight: FontWeight.w600,
            color: AppColors.gold,
            letterSpacing: letterSpacing,
            height: 1,
          ),
        ),
      ],
    );
  }
}
