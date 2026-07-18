import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../theme/app_dimens.dart';

/// Sticky bottom action bar on Listing Detail: save toggle + either a
/// "Request to Buy" button, or (once requested) Call / WhatsApp buttons.
class DetailCtaBar extends StatelessWidget {
  final bool isFavorite;
  final bool hasRequestedBuy;
  final VoidCallback onToggleFavorite;
  final VoidCallback onRequestBuy;
  final VoidCallback onCall;
  final VoidCallback onWhatsApp;

  const DetailCtaBar({
    super.key,
    required this.isFavorite,
    required this.hasRequestedBuy,
    required this.onToggleFavorite,
    required this.onRequestBuy,
    required this.onCall,
    required this.onWhatsApp,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(AppSpacing.s18, AppSpacing.s12, AppSpacing.s18, AppSpacing.s16),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppColors.divider)),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: onToggleFavorite,
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppRadii.r14),
                border: Border.all(color: AppColors.gold, width: 1.5),
              ),
              child: Icon(isFavorite ? Icons.favorite : Icons.favorite_border, color: AppColors.gold, size: 20),
            ),
          ),
          const SizedBox(width: AppSpacing.s10),
          if (!hasRequestedBuy)
            Expanded(
              child: GestureDetector(
                onTap: onRequestBuy,
                child: Container(
                  height: 48,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(color: AppColors.nileGreen, borderRadius: BorderRadius.circular(AppRadii.r14)),
                  child: Text('Request to Buy', style: AppFonts.tajawal(size: 14, weight: FontWeight.w700, color: Colors.white)),
                ),
              ),
            )
          else ...[
            Expanded(
              child: GestureDetector(
                onTap: onCall,
                child: Container(
                  height: 48,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.sandy,
                    borderRadius: BorderRadius.circular(AppRadii.r14),
                    border: Border.all(color: AppColors.deepGreen, width: 1.5),
                  ),
                  child: Text('Call', style: AppFonts.tajawal(size: 14, weight: FontWeight.w700, color: AppColors.deepGreen)),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.s10),
            Expanded(
              child: GestureDetector(
                onTap: onWhatsApp,
                child: Container(
                  height: 48,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(color: AppColors.nileGreen, borderRadius: BorderRadius.circular(AppRadii.r14)),
                  child: Text('WhatsApp', style: AppFonts.tajawal(size: 14, weight: FontWeight.w700, color: Colors.white)),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
