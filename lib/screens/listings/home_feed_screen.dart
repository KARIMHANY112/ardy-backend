import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../data/mock_listings.dart';
import '../../models/listing.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_bottom_nav.dart';
import '../../widgets/listing_card.dart';

class HomeFeedScreen extends StatefulWidget {
  const HomeFeedScreen({super.key});

  @override
  State<HomeFeedScreen> createState() => _HomeFeedScreenState();
}

class _HomeFeedScreenState extends State<HomeFeedScreen> {
  ListingCategory? _selectedCategory;
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final listings = mockListings.where((l) => _selectedCategory == null || l.category == _selectedCategory).toList();

    return AppBottomNavScaffold(
      currentIndex: 0,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: [
                Image.asset('assets/green_logo.png', height: 32),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: const InputDecoration(
                      hintText: 'Search listings...',
                      prefixIcon: Icon(Icons.search),
                      isDense: true,
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 44,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _CategoryChip(
                  label: 'All',
                  selected: _selectedCategory == null,
                  onTap: () => setState(() => _selectedCategory = null),
                ),
                for (final category in ListingCategory.values)
                  Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: _CategoryChip(
                      label: category.label,
                      selected: _selectedCategory == category,
                      onTap: () => setState(() => _selectedCategory = category),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: listings.length,
              separatorBuilder: (_, _) => const SizedBox(height: 14),
              itemBuilder: (context, index) {
                final listing = listings[index];
                return ListingCard(
                  listing: listing,
                  onTap: () => context.push('/listing/${listing.id}'),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _CategoryChip({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
      selectedColor: AppColors.nileGreen,
      labelStyle: TextStyle(color: selected ? Colors.white : AppColors.ink),
    );
  }
}
