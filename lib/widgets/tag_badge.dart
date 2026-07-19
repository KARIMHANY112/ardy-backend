import 'package:flutter/material.dart';

import '../models/listing.dart';
import '../theme/app_theme.dart';
import '../theme/app_dimens.dart';

/// Small sandy-bg pill tag. Used both as the category tag on Listing Detail
/// ("FACTORY") and as the license-status badge on listing cards.
class TagBadge extends StatelessWidget {
  final String text;
  final Color color;

  const TagBadge({super.key, required this.text, required this.color});

  /// Recolors per the design handoff: licensed = deep green, pending = amber,
  /// n/a = muted ink.
  factory TagBadge.license(LicenseStatus status) {
    final color = switch (status) {
      LicenseStatus.licensed => AppColors.deepGreen,
      LicenseStatus.pending => AppColors.pendingAmber,
      LicenseStatus.notApplicable => AppColors.inkAlpha(0.6),
    };
    return TagBadge(text: status.label, color: color);
  }

  /// The selling status shown on browse cards — available (live), papers
  /// pending, or sold. Distinct from [license], which is about the property's
  /// registration paperwork, not whether it's for sale.
  factory TagBadge.saleStatus(ListingStatus status) {
    final (text, color) = switch (status) {
      ListingStatus.live => ('AVAILABLE', AppColors.nileGreen),
      ListingStatus.papersPending => ('PAPERS PENDING', AppColors.pendingAmber),
      ListingStatus.sold => ('SOLD', AppColors.ink),
      ListingStatus.pending => ('PENDING REVIEW', AppColors.pendingAmber),
      ListingStatus.rejected => ('REJECTED', Colors.redAccent),
    };
    return TagBadge(text: text, color: color);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s8, vertical: AppSpacing.s3),
      decoration: BoxDecoration(color: AppColors.sandy, borderRadius: BorderRadius.circular(AppRadii.r6)),
      child: Text(text, style: AppFonts.tajawal(size: 10, weight: FontWeight.w600, color: color)),
    );
  }
}
