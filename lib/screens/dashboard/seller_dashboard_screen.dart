import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../data/mock_listings.dart';
import '../../models/listing.dart';
import '../../theme/app_theme.dart';
import '../../widgets/dashboard_link_card.dart';

class SellerDashboardScreen extends StatelessWidget {
  const SellerDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    // Stub: stands in for "my listings" until GET /listings?mine=true is wired up.
    final myListings = mockListings.take(2).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Seller Dashboard')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text('Welcome back', style: textTheme.headlineMedium),
            const SizedBox(height: 4),
            Text(
              'Manage your listings or post a new one.',
              style: textTheme.bodyMedium?.copyWith(color: AppColors.ink.withValues(alpha: 0.6)),
            ),
            const SizedBox(height: 20),
            DashboardLinkCard(
              icon: Icons.add_box_outlined,
              title: 'Post New Listing',
              subtitle: 'Submit a listing for owner review',
              onTap: () => context.go('/post-listing'),
            ),
            const SizedBox(height: 20),
            Text('My Listings', style: textTheme.titleLarge),
            const SizedBox(height: 12),
            for (final listing in myListings)
              Card(
                margin: const EdgeInsets.only(bottom: 10),
                child: ListTile(
                  leading: const CircleAvatar(backgroundColor: AppColors.sandy, child: Icon(Icons.photo_outlined, color: AppColors.divider)),
                  title: Text(listing.title),
                  subtitle: Text('${listing.category.label} · ${listing.location}'),
                  trailing: _StatusPill(status: listing.license),
                  onTap: () => context.push('/listing/${listing.id}'),
                ),
              ),
            const SizedBox(height: 8),
            DashboardLinkCard(
              icon: Icons.chat_bubble_outline,
              title: 'Land Advisor',
              subtitle: 'See what buyers are looking for',
              onTap: () => context.go('/advisor'),
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

class _StatusPill extends StatelessWidget {
  final LicenseStatus status;

  const _StatusPill({required this.status});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: AppColors.sandy, borderRadius: BorderRadius.circular(20)),
      child: Text(status.label, style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 12)),
    );
  }
}
