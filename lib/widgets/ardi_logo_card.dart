import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// The large logo lockup card shown at the top of Sign Up / Log In.
///
/// The design handoff's source PNGs (`logo-light-bg.png` / `logo-dark-bg.png`)
/// are brand-brief excerpts with crop marks and captions baked in — not
/// production assets (see the handoff README). This rebuilds the same
/// lockup as a real widget instead: [light] = sandy card with the green
/// wordmark (Sign Up), false = deep-green card with the white wordmark
/// (Log In).
class ArdiLogoCard extends StatelessWidget {
  final bool light;

  const ArdiLogoCard({super.key, this.light = true});

  @override
  Widget build(BuildContext context) {
    final cardColor = light ? AppColors.sandy : AppColors.deepGreen;
    final wordmarkColor = light ? AppColors.nileGreen : Colors.white;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 28),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 20, offset: const Offset(0, 6))],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'ارضي',
            textDirection: TextDirection.rtl,
            style: AppFonts.cairo(size: 34, weight: FontWeight.w800, color: wordmarkColor, height: 1),
          ),
          const SizedBox(height: 6),
          Text(
            'A R D I',
            style: AppFonts.tajawal(size: 13, weight: FontWeight.w600, color: AppColors.gold, letterSpacing: 4),
          ),
        ],
      ),
    );
  }
}
