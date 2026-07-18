import 'package:flutter/material.dart';

import '../models/listing.dart';
import '../theme/app_theme.dart';
import '../theme/app_dimens.dart';
import '../utils/formatters.dart';
import 'listing_photo.dart';
import 'tag_badge.dart';

/// The compact 2-column grid card used on the Favorites screen, with a
/// filled-heart save toggle floating over the photo.
class FavoriteGridCard extends StatelessWidget {
  final Listing listing;
  final VoidCallback onTap;
  final VoidCallback? onFavoriteToggle;

  const FavoriteGridCard({super.key, required this.listing, required this.onTap, this.onFavoriteToggle});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppRadii.r16),
          boxShadow: [BoxShadow(color: AppColors.deepGreen.withValues(alpha: 0.08), blurRadius: 12, offset: const Offset(0, 4))],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                Container(
                  height: 100,
                  width: double.infinity,
                  color: AppColors.sandy,
                  child: ListingPhoto(photoUrls: listing.photoUrls, iconSize: 28),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: GestureDetector(
                    onTap: onFavoriteToggle,
                    child: Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.9), shape: BoxShape.circle),
                      child: const Icon(Icons.favorite, size: 13, color: AppColors.gold),
                    ),
                  ),
                ),
                if (listing.status == ListingStatus.sold)
                  const Positioned(
                    top: 8,
                    left: 8,
                    child: TagBadge(text: 'SOLD', color: AppColors.ink),
                  ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.s10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    listing.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppFonts.cairo(size: 12, weight: FontWeight.w700),
                  ),
                  const SizedBox(height: AppSpacing.s2),
                  Text(formatEgp(listing.price), style: AppFonts.tajawal(size: 12, weight: FontWeight.w700, color: AppColors.gold)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
