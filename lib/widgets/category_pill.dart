import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../theme/app_dimens.dart';

/// Single-select pill used for category/license/role filters throughout the
/// app (Home & Favorites category filters, Post Listing category + license
/// selectors). Filled nile-green when selected, outlined divider-gray otherwise.
class CategoryPill extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const CategoryPill({super.key, required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s16, vertical: AppSpacing.s8),
        decoration: BoxDecoration(
          color: selected ? AppColors.nileGreen : Colors.transparent,
          borderRadius: BorderRadius.circular(AppRadii.pill),
          border: selected ? null : Border.all(color: AppColors.divider, width: 1.5),
        ),
        child: Text(
          label,
          style: AppFonts.tajawal(
            size: 12,
            weight: FontWeight.w600,
            color: selected ? Colors.white : AppColors.ink,
          ),
        ),
      ),
    );
  }
}
