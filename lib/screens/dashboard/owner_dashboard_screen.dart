import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../data/mock_listings.dart';
import '../../models/listing.dart';
import '../../theme/app_theme.dart';

class OwnerDashboardScreen extends StatelessWidget {
  const OwnerDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    // Stub: stands in for GET /listings?status=pending until wired up.
    final pending = mockListings.take(3).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Owner Dashboard'),
        actions: [
          IconButton(icon: const Icon(Icons.logout), onPressed: () => context.go('/login')),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Row(
              children: [
                Expanded(child: _StatCard(label: 'Pending Review', value: '${pending.length}')),
                const SizedBox(width: 12),
                const Expanded(child: _StatCard(label: 'Live Listings', value: '—')),
                const SizedBox(width: 12),
                const Expanded(child: _StatCard(label: 'Total Users', value: '—')),
              ],
            ),
            const SizedBox(height: 24),
            Text('Pending Listings', style: textTheme.titleLarge),
            const SizedBox(height: 12),
            for (final listing in pending)
              Card(
                margin: const EdgeInsets.only(bottom: 10),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(listing.title, style: textTheme.titleMedium),
                      const SizedBox(height: 4),
                      Text(
                        '${listing.category.label} · ${listing.sizeSqm.toStringAsFixed(0)} sqm · ${listing.location}',
                        style: textTheme.bodyMedium?.copyWith(color: AppColors.ink.withValues(alpha: 0.6)),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => _stubAction(context, 'Rejected'),
                              child: const Text('Reject'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () => _stubAction(context, 'Approved'),
                              child: const Text('Approve'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _stubAction(BuildContext context, String action) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$action (not wired up yet)')));
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;

  const _StatCard({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        child: Column(
          children: [
            Text(value, style: textTheme.headlineMedium?.copyWith(color: AppColors.nileGreen)),
            const SizedBox(height: 4),
            Text(label, textAlign: TextAlign.center, style: textTheme.bodyMedium?.copyWith(fontSize: 12)),
          ],
        ),
      ),
    );
  }
}
