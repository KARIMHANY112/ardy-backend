import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../theme/app_dimens.dart';
import 'listing_photo.dart';

/// Hero photo gallery on Listing Detail: back button + save toggle overlaid
/// on the photo, with a page-dot indicator along the bottom edge.
class ListingGalleryHeader extends StatefulWidget {
  final bool isFavorite;
  final VoidCallback onBack;
  final VoidCallback onToggleFavorite;
  final List<String> photoUrls;

  const ListingGalleryHeader({
    super.key,
    required this.isFavorite,
    required this.onBack,
    required this.onToggleFavorite,
    this.photoUrls = const [],
  });

  @override
  State<ListingGalleryHeader> createState() => _ListingGalleryHeaderState();
}

class _ListingGalleryHeaderState extends State<ListingGalleryHeader> {
  final _pageController = PageController();
  int _page = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final photoCount = widget.photoUrls.isEmpty ? 1 : widget.photoUrls.length;
    return SizedBox(
      height: 280,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Container(
            color: AppColors.sandy,
            child: widget.photoUrls.length <= 1
                ? ListingPhoto(photoUrls: widget.photoUrls, iconSize: 48)
                : PageView.builder(
                    controller: _pageController,
                    onPageChanged: (index) => setState(() => _page = index),
                    itemCount: widget.photoUrls.length,
                    itemBuilder: (context, index) => ListingPhoto(photoUrls: [widget.photoUrls[index]], iconSize: 48),
                  ),
          ),
          Positioned(
            top: 12,
            left: 14,
            child: _CircleButton(icon: Icons.arrow_back_ios_new, onTap: widget.onBack, iconColor: AppColors.ink, iconSize: 16),
          ),
          Positioned(
            top: 12,
            right: 14,
            child: _CircleButton(
              icon: widget.isFavorite ? Icons.favorite : Icons.favorite_border,
              onTap: widget.onToggleFavorite,
              iconColor: AppColors.gold,
              iconSize: 18,
            ),
          ),
          Positioned(
            bottom: 12,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                photoCount,
                (index) => Container(
                  margin: const EdgeInsets.symmetric(horizontal: AppSpacing.s2_5),
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: index == _page ? AppColors.gold : Colors.white.withValues(alpha: 0.55),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CircleButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final Color iconColor;
  final double iconSize;

  const _CircleButton({required this.icon, required this.onTap, required this.iconColor, required this.iconSize});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.92), shape: BoxShape.circle),
        child: Icon(icon, size: iconSize, color: iconColor),
      ),
    );
  }
}
