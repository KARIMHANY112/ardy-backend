import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../theme/app_theme.dart';
import '../../widgets/dashboard_link_card.dart';

class BuyerDashboardScreen extends StatelessWidget {
  const BuyerDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Buyer Dashboard')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text('Welcome back', style: textTheme.headlineMedium),
            const SizedBox(height: 4),
            Text(
              'Browse listings, chat with the Land Advisor, or check your saved properties.',
              style: textTheme.bodyMedium?.copyWith(color: AppColors.ink.withValues(alpha: 0.6)),
            ),
            const SizedBox(height: 20),
            DashboardLinkCard(
              icon: Icons.home_outlined,
              title: 'Browse Listings',
              subtitle: 'Search factories, land, and shops',
              onTap: () => context.go('/home'),
            ),
            const SizedBox(height: 12),
            DashboardLinkCard(
              icon: Icons.chat_bubble_outline,
              title: 'Land Advisor',
              subtitle: 'Get AI-matched recommendations',
              onTap: () => context.go('/advisor'),
            ),
            const SizedBox(height: 12),
            DashboardLinkCard(
              icon: Icons.favorite_border,
              title: 'Favorites',
              subtitle: 'View your saved listings',
              onTap: () => context.go('/favorites'),
            ),
            const SizedBox(height: 12),
            DashboardLinkCard(
              icon: Icons.person_outline,
              title: 'Profile',
              subtitle: 'Account settings',
              onTap: () => context.go('/profile'),
            ),
          ],
        ),
      ),
    );
  }
}
