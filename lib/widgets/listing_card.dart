import 'package:flutter/material.dart';

import '../models/listing.dart';
import '../theme/app_theme.dart';

class ListingCard extends StatelessWidget {
  final Listing listing;
  final VoidCallback onTap;
  final VoidCallback? onFavoriteToggle;

  const ListingCard({super.key, required this.listing, required this.onTap, this.onFavoriteToggle});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                Container(
                  height: 150,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: AppColors.sandy,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
                    border: Border.all(color: AppColors.divider),
                  ),
                  child: const Center(
                    child: Icon(Icons.photo_outlined, size: 36, color: AppColors.divider),
                  ),
                ),
                Positioned(
                  top: 10,
                  right: 10,
                  child: GestureDetector(
                    onTap: onFavoriteToggle,
                    child: CircleAvatar(
                      radius: 16,
                      backgroundColor: Colors.white,
                      child: Icon(
                        listing.isFavorite ? Icons.favorite : Icons.favorite_border,
                        size: 18,
                        color: AppColors.gold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(listing.title, style: textTheme.titleMedium, maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 6),
                  Text(
                    '${listing.category.label} · ${listing.sizeSqm.toStringAsFixed(0)} sqm · ${listing.location}',
                    style: textTheme.bodyMedium?.copyWith(color: AppColors.ink.withValues(alpha: 0.6)),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${listing.price.toStringAsFixed(0)} EGP',
                        style: textTheme.titleMedium?.copyWith(color: AppColors.gold, fontWeight: FontWeight.w700),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.sandy,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(listing.license.label, style: textTheme.bodyMedium?.copyWith(fontSize: 12)),
                      ),
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
