import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../data/mock_listings.dart';
import '../../models/listing.dart';
import '../../theme/app_theme.dart';

class ListingDetailScreen extends StatelessWidget {
  final String listingId;

  const ListingDetailScreen({super.key, required this.listingId});

  @override
  Widget build(BuildContext context) {
    final listing = mockListings.firstWhere(
      (l) => l.id == listingId,
      orElse: () => mockListings.first,
    );
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Stack(
                      children: [
                        Container(
                          height: 240,
                          width: double.infinity,
                          color: AppColors.sandy,
                          child: const Center(
                            child: Icon(Icons.photo_outlined, size: 48, color: AppColors.divider),
                          ),
                        ),
                        Positioned(
                          top: 12,
                          left: 12,
                          child: CircleAvatar(
                            backgroundColor: Colors.white,
                            child: IconButton(
                              icon: const Icon(Icons.arrow_back),
                              onPressed: () => context.pop(),
                            ),
                          ),
                        ),
                        const Positioned(
                          top: 12,
                          right: 12,
                          child: CircleAvatar(
                            backgroundColor: Colors.white,
                            child: Icon(Icons.favorite_border, color: AppColors.gold),
                          ),
                        ),
                      ],
                    ),
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(listing.title, style: textTheme.headlineMedium),
                          const SizedBox(height: 4),
                          Text(
                            '${listing.category.label} · ${listing.location}',
                            style: textTheme.bodyMedium?.copyWith(color: AppColors.ink.withValues(alpha: 0.6)),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            '${listing.price.toStringAsFixed(0)} EGP',
                            style: textTheme.headlineMedium?.copyWith(color: AppColors.gold),
                          ),
                          const SizedBox(height: 20),
                          GridView.count(
                            crossAxisCount: 2,
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            mainAxisSpacing: 12,
                            crossAxisSpacing: 12,
                            childAspectRatio: 2.6,
                            children: [
                              _FactCell(label: 'Area', value: '${listing.sizeSqm.toStringAsFixed(0)} sqm'),
                              _FactCell(
                                label: 'Price/sqm',
                                value: '${(listing.price / listing.sizeSqm).toStringAsFixed(0)} EGP',
                              ),
                              _FactCell(label: 'License', value: listing.license.label),
                              _FactCell(label: 'Ref Code', value: listing.refCode),
                            ],
                          ),
                          const SizedBox(height: 20),
                          Text('Description', style: textTheme.titleMedium),
                          const SizedBox(height: 8),
                          Text(listing.description, style: textTheme.bodyMedium),
                          const SizedBox(height: 20),
                          Text('Location', style: textTheme.titleMedium),
                          const SizedBox(height: 8),
                          Container(
                            height: 120,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: AppColors.sandy,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: AppColors.divider),
                            ),
                            child: const Center(child: Icon(Icons.map_outlined, color: AppColors.divider, size: 32)),
                          ),
                          const SizedBox(height: 20),
                          Card(
                            child: Padding(
                              padding: const EdgeInsets.all(14),
                              child: Row(
                                children: [
                                  const CircleAvatar(radius: 22, backgroundColor: AppColors.sandy, child: Icon(Icons.person, color: AppColors.ink)),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text('Listing Agent', style: textTheme.titleMedium),
                                        Text('Ardy verified seller', style: textTheme.bodyMedium),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _showStub(context, 'Call'),
                        icon: const Icon(Icons.call_outlined),
                        label: const Text('Call'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _showStub(context, 'WhatsApp'),
                        icon: const Icon(Icons.chat_outlined),
                        label: const Text('WhatsApp'),
                        style: ElevatedButton.styleFrom(backgroundColor: AppColors.deepGreen),
                      ),
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

  void _showStub(BuildContext context, String action) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$action tapped — not wired up yet')));
  }
}

class _FactCell extends StatelessWidget {
  final String label;
  final String value;

  const _FactCell({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(color: AppColors.sandy, borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(label, style: textTheme.bodyMedium?.copyWith(fontSize: 12, color: AppColors.ink.withValues(alpha: 0.6))),
          Text(value, style: textTheme.titleMedium),
        ],
      ),
    );
  }
}
