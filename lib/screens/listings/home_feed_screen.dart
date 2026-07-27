import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../l10n/generated/app_localizations.dart';
import '../../models/listing.dart';
import '../../services/api_client.dart';
import '../../services/listings_repository.dart';
import '../../theme/app_theme.dart';
import '../../theme/app_dimens.dart';
import '../../widgets/app_bottom_nav.dart';
import '../../widgets/ardi_wordmark.dart';
import '../../widgets/category_pill.dart';
import '../../widgets/listing_card.dart';
import '../../widgets/search_field.dart';

/// Home / Listings Feed — direction 1a "Grid Market": white header, sandy
/// page bg, pill category chips, vertically-stacked white rounded cards.
class HomeFeedScreen extends StatefulWidget {
  const HomeFeedScreen({super.key});

  @override
  State<HomeFeedScreen> createState() => _HomeFeedScreenState();
}

class _HomeFeedScreenState extends State<HomeFeedScreen> {
  // Same contact number used everywhere else in the app for reaching the
  // Ardi team directly — wa.me needs intl format, no leading 0.
  static const _contactPhoneIntl = '201282092054';

  ListingCategory? _selectedCategory;
  final _searchController = TextEditingController();
  String _query = '';

  late Future<List<Listing>> _listingsFuture;

  // Filter-chip copy is plural ("Factories") while selectors elsewhere use
  // the singular ListingCategory.label — matches the design handoff's copy.
  Map<ListingCategory, String> _filterLabels(AppLocalizations l10n) => {
        ListingCategory.factory: l10n.filterFactories,
        ListingCategory.land: l10n.filterLand,
        ListingCategory.shop: l10n.filterShops,
      };

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    _listingsFuture = context.read<ListingsRepository>().browse();
  }

  Future<void> _refresh() async {
    setState(_load);
    await _listingsFuture;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _openWhatsApp() async {
    final text = Uri.encodeComponent(AppLocalizations.of(context)!.listPropertyWhatsappMessage);
    await launchUrl(Uri.parse('https://wa.me/$_contactPhoneIntl?text=$text'), mode: LaunchMode.externalApplication);
  }

  List<Listing> _filter(List<Listing> listings) => listings.where((l) {
        final matchesCategory = _selectedCategory == null || l.category == _selectedCategory;
        final matchesQuery = _query.isEmpty || l.title.toLowerCase().contains(_query.toLowerCase()) || l.location.toLowerCase().contains(_query.toLowerCase());
        return matchesCategory && matchesQuery;
      }).toList();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final filterLabels = _filterLabels(l10n);
    return AppBottomNavScaffold(
      currentIndex: 0,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(AppSpacing.s18, AppSpacing.s16, AppSpacing.s18, AppSpacing.s14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const ArdiWordmark(),
                    GestureDetector(
                      onTap: _openWhatsApp,
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: const BoxDecoration(color: AppColors.nileGreen, shape: BoxShape.circle),
                        child: const Icon(Icons.add, color: Colors.white, size: 22),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.s12),
                ArdiSearchField(
                  controller: _searchController,
                  hint: l10n.searchHint,
                  onChanged: (value) => setState(() => _query = value),
                ),
                const SizedBox(height: AppSpacing.s12),
                SizedBox(
                  height: 32,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      CategoryPill(label: l10n.filterAll, selected: _selectedCategory == null, onTap: () => setState(() => _selectedCategory = null)),
                      for (final category in ListingCategory.values)
                        Padding(
                          padding: const EdgeInsets.only(left: AppSpacing.s8),
                          child: CategoryPill(
                            label: filterLabels[category]!,
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
              future: _listingsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  final message = snapshot.error is ApiException ? (snapshot.error as ApiException).message : l10n.couldNotLoadListings;
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(message, style: AppFonts.tajawal(size: 14, weight: FontWeight.w400, color: AppColors.inkAlpha(0.6))),
                        const SizedBox(height: AppSpacing.s8),
                        TextButton(onPressed: _refresh, child: Text(l10n.retry)),
                      ],
                    ),
                  );
                }

                final listings = _filter(snapshot.data!);
                return RefreshIndicator(
                  onRefresh: _refresh,
                  child: listings.isEmpty
                      ? ListView(
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(top: AppSpacing.s80),
                              child: Center(child: Text(l10n.noListingsMatch, style: AppFonts.tajawal(size: 14, weight: FontWeight.w400, color: AppColors.inkAlpha(0.6)))),
                            ),
                          ],
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(AppSpacing.s18, AppSpacing.s16, AppSpacing.s18, AppSpacing.s6),
                          itemCount: listings.length,
                          separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.s14),
                          itemBuilder: (context, index) {
                            final listing = listings[index];
                            return ListingCard(listing: listing, onTap: () => context.push('/listing/${listing.id}'));
                          },
                        ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
