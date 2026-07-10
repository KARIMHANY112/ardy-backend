import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Quick-access card used on the role dashboards to route into the shared screens.
class DashboardLinkCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const DashboardLinkCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(backgroundColor: AppColors.sandy, child: Icon(icon, color: AppColors.nileGreen)),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: textTheme.titleMedium),
                    Text(subtitle, style: textTheme.bodyMedium?.copyWith(color: AppColors.ink.withValues(alpha: 0.6))),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: AppColors.ink),
            ],
          ),
        ),
      ),
    );
  }
}
