import 'package:flutter/material.dart';

import '../l10n/generated/app_localizations.dart';
import '../models/listing.dart';
import '../theme/app_theme.dart';
import '../theme/app_dimens.dart';
import '../utils/formatters.dart';
import 'listing_photo.dart';
import 'tag_badge.dart';

/// The vertical listing card used in the Home Feed list.
class ListingCard extends StatelessWidget {
  final Listing listing;
  final VoidCallback onTap;

  const ListingCard({super.key, required this.listing, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppRadii.r18),
          boxShadow: AppColors.cardShadow,
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                Container(
                  height: 150,
                  width: double.infinity,
                  color: AppColors.sandy,
                  child: ListingPhoto(photoUrls: listing.photoUrls, iconSize: 36),
                ),
                PositionedDirectional(
                  top: AppSpacing.s8,
                  start: AppSpacing.s8,
                  child: TagBadge.offerType(context, listing.offerType),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s14, vertical: AppSpacing.s12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    listing.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppFonts.cairo(size: 15, weight: FontWeight.w700),
                  ),
                  const SizedBox(height: AppSpacing.s6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Flexible: a rental price carries its period ("/month"), which
                      // can crowd the size out on a narrow screen.
                      Flexible(
                        child: Text(
                          listing.priceLabel(context),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppFonts.tajawal(size: 14, weight: FontWeight.w700, color: AppColors.gold),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.s8),
                      Text(formatSqm(listing.sizeSqm, AppLocalizations.of(context)!.sqmSuffix), style: AppFonts.tajawal(size: 12, weight: FontWeight.w400, color: AppColors.inkAlpha(0.6))),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.s4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          listing.location,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppFonts.tajawal(size: 12, weight: FontWeight.w400, color: AppColors.inkAlpha(0.6)),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.s8),
                      TagBadge.saleStatus(context, listing.status),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
