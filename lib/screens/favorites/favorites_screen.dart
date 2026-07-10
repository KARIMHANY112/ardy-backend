import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../data/mock_listings.dart';
import '../../widgets/app_bottom_nav.dart';
import '../../widgets/listing_card.dart';

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final favorites = mockListings.where((l) => l.isFavorite).toList();

    return AppBottomNavScaffold(
      currentIndex: 1,
      title: 'Favorites',
      body: favorites.isEmpty
          ? const Center(child: Text('No saved listings yet'))
          : GridView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: favorites.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 14,
                crossAxisSpacing: 14,
                childAspectRatio: 0.72,
              ),
              itemBuilder: (context, index) {
                final listing = favorites[index];
                return ListingCard(listing: listing, onTap: () => context.push('/listing/${listing.id}'));
              },
            ),
    );
  }
}
