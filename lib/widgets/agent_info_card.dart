import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../theme/app_dimens.dart';

/// Listing-agent row shown near the bottom of Listing Detail.
class AgentInfoCard extends StatelessWidget {
  final String name;
  final String subtitle;

  const AgentInfoCard({super.key, required this.name, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.s10),
      decoration: BoxDecoration(color: AppColors.sandy, borderRadius: BorderRadius.circular(AppRadii.r14)),
      child: Row(
        children: [
          const CircleAvatar(radius: 22, backgroundColor: Colors.white, child: Icon(Icons.person, color: AppColors.ink)),
          const SizedBox(width: AppSpacing.s10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: AppFonts.tajawal(size: 13, weight: FontWeight.w700)),
                Text(subtitle, style: AppFonts.tajawal(size: 11, weight: FontWeight.w400, color: AppColors.inkAlpha(0.6))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
