import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Fills its parent with the listing's first photo, or the placeholder icon
/// when there isn't one (still pending upload, or upload failed).
class ListingPhoto extends StatelessWidget {
  final List<String> photoUrls;
  final double iconSize;

  const ListingPhoto({super.key, required this.photoUrls, this.iconSize = 36});

  @override
  Widget build(BuildContext context) {
    if (photoUrls.isEmpty) {
      return Center(child: Icon(Icons.photo_outlined, size: iconSize, color: AppColors.divider));
    }
    return Image.network(
      photoUrls.first,
      fit: BoxFit.cover,
      width: double.infinity,
      height: double.infinity,
      loadingBuilder: (context, child, progress) => progress == null ? child : const Center(child: CircularProgressIndicator(strokeWidth: 2)),
      errorBuilder: (context, error, stackTrace) => Center(child: Icon(Icons.photo_outlined, size: iconSize, color: AppColors.divider)),
    );
  }
}
