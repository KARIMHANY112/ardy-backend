import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../models/listing.dart';
import '../../services/api_client.dart';
import '../../services/favorites_repository.dart';
import '../../theme/app_theme.dart';
import '../../theme/app_dimens.dart';
import '../../widgets/app_bottom_nav.dart';
import '../../widgets/brand_header.dart';
import '../../widgets/category_pill.dart';
import '../../widgets/favorite_grid_card.dart';

/// Favorites — direction 1a: 2-column card grid, each with a filled-heart
/// save indicator.
class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  ListingCategory? _selectedCategory;
  late Future<List<Listing>> _favoritesFuture;

  static const _filterLabels = {
    ListingCategory.factory: 'Factories',
    ListingCategory.land: 'Land',
    ListingCategory.shop: 'Shops',
  };

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    _favoritesFuture = context.read<FavoritesRepository>().list().then(
          (favorites) => favorites.map((f) => f.listing.copyWith(isFavorite: true)).toList(),
        );
  }

  Future<void> _removeFavorite(String listingId) async {
    try {
      await context.read<FavoritesRepository>().remove(listingId);
      setState(_load);
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppBottomNavScaffold(
      currentIndex: 1,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(AppSpacing.s18, AppSpacing.s16, AppSpacing.s18, AppSpacing.s14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const BrandHeader(title: 'Favorites', titleSize: 22),
                const SizedBox(height: AppSpacing.s12),
                SizedBox(
                  height: 32,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      CategoryPill(label: 'All', selected: _selectedCategory == null, onTap: () => setState(() => _selectedCategory = null)),
                      for (final category in ListingCategory.values)
                        Padding(
                          padding: const EdgeInsets.only(left: AppSpacing.s8),
                          child: CategoryPill(
                            label: _filterLabels[category]!,
                            selected: _selectedCategory == category,
                            onTap: () => setState(() => _selectedCategory = category),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: FutureBuilder<List<Listing>>(
              future: _favoritesFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  final message = snapshot.error is ApiException ? (snapshot.error as ApiException).message : 'Could not load favorites';
                  return Center(child: Text(message, style: AppFonts.tajawal(size: 14, weight: FontWeight.w400, color: AppColors.inkAlpha(0.6))));
                }

                final favorites = snapshot.data!.where((l) => _selectedCategory == null || l.category == _selectedCategory).toList();
                if (favorites.isEmpty) {
                  return Center(child: Text('No saved listings yet', style: AppFonts.tajawal(size: 14, weight: FontWeight.w400, color: AppColors.inkAlpha(0.6))));
                }
                return GridView.builder(
                  padding: const EdgeInsets.all(AppSpacing.s18),
                  itemCount: favorites.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 0.82,
                  ),
                  itemBuilder: (context, index) {
                    final listing = favorites[index];
                    return FavoriteGridCard(
                      listing: listing,
                      onTap: listing.status == ListingStatus.live
                          ? () => context.push('/listing/${listing.id}')
                          : () => ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('${listing.title} is ${listing.status.label.toLowerCase()}')),
                              ),
                      onFavoriteToggle: () => _removeFavorite(listing.id),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
