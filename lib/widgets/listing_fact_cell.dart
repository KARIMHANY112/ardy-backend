import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// One cell in the 2x2 facts grid on Listing Detail (Area / License / Type / Ref Code).
class ListingFactCell extends StatelessWidget {
  final String label;
  final String value;

  const ListingFactCell({super.key, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: AppColors.sandy, borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(label, style: AppFonts.tajawal(size: 11, weight: FontWeight.w600, color: AppColors.inkAlpha(0.6))),
          const SizedBox(height: 4),
          Text(value, style: AppFonts.cairo(size: 15, weight: FontWeight.w700)),
        ],
      ),
    );
  }
}
