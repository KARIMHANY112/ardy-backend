import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../models/listing.dart';
import '../theme/app_theme.dart';
import '../theme/app_dimens.dart';
import '../utils/formatters.dart';
import 'listing_photo.dart';

/// The inline "comparison panel" message type the Land Advisor renders
/// alongside its text replies — a horizontally-scrolling strip of mini
/// listing tiles.
class ComparisonCard extends StatelessWidget {
  final List<Listing> listings;

  const ComparisonCard({super.key, required this.listings});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.s12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(AppRadii.r16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Comparing ${listings.length} listings', style: AppFonts.cairo(size: 12, weight: FontWeight.w700)),
          const SizedBox(height: AppSpacing.s8),
          SizedBox(
            height: 124,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: listings.length,
              separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.s10),
              itemBuilder: (context, index) {
                final listing = listings[index];
                return GestureDetector(
                  onTap: () => context.push('/listing/${listing.id}'),
                  child: SizedBox(
                    width: 140,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          height: 80,
                          width: double.infinity,
                          clipBehavior: Clip.antiAlias,
                          decoration: BoxDecoration(color: AppColors.sandy, borderRadius: BorderRadius.circular(AppRadii.r10)),
                          child: ListingPhoto(photoUrls: listing.photoUrls, iconSize: 20),
                        ),
                        const SizedBox(height: AppSpacing.s4),
                        Text(
                          listing.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppFonts.tajawal(size: 11, weight: FontWeight.w600),
                        ),
                        Text(formatEgp(listing.price), style: AppFonts.tajawal(size: 12, weight: FontWeight.w700, color: AppColors.gold)),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
