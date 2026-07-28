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
import '../../widgets/filter_sheet.dart';
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

  ListingFilters _filters = const ListingFilters();
  final _searchController = TextEditingController();
  String _query = '';

  late Future<List<Listing>> _listingsFuture;

  /// The listings currently loaded, so the filter sheet can show a live result
  /// count for a draft selection before it's applied. Empty until the fetch lands.
  List<Listing> _loaded = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    final future = context.read<ListingsRepository>().browse();
    _listingsFuture = future;
    // Mirror the result into state rather than reading it off the FutureBuilder's
    // snapshot: the header (and its filter button) is built before that builder
    // runs, so a value captured there would never reach this rebuild.
    // The FutureBuilder below owns error rendering — swallow here so this
    // side-channel can't surface a second, unhandled failure.
    future.then(
      (listings) {
        if (mounted) setState(() => _loaded = listings);
      },
      onError: (_) {
        if (mounted) setState(() => _loaded = const []);
      },
    );
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

  List<Listing> _filter(List<Listing> listings, ListingFilters filters) => listings.where((l) {
        final matchesQuery = _query.isEmpty || l.title.toLowerCase().contains(_query.toLowerCase()) || l.location.toLowerCase().contains(_query.toLowerCase());
        return filters.matches(l) && matchesQuery;
      }).toList();

  Future<void> _openFilters() async {
    final chosen = await showListingFilterSheet(
      context,
      current: _filters,
      // Counted against the search query too, so "Show N results" is the number
      // the buyer will actually land on.
      countMatches: (draft) => _filter(_loaded, draft).length,
    );
    if (chosen != null && mounted) setState(() => _filters = chosen);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
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
                Row(
                  children: [
                    Expanded(
                      child: ArdiSearchField(
                        controller: _searchController,
                        hint: l10n.searchHint,
                        onChanged: (value) => setState(() => _query = value),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.s10),
                    _FilterButton(activeCount: _filters.activeCount, onTap: _loaded.isEmpty ? null : _openFilters),
                  ],
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

                final listings = _filter(snapshot.data!, _filters);
                return Column(
                  children: [
                    _ResultsBar(
                      count: listings.length,
                      showClear: !_filters.isEmpty,
                      onClear: () => setState(() => _filters = const ListingFilters()),
                    ),
                    Expanded(child: _buildList(listings)),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildList(List<Listing> listings) {
    final l10n = AppLocalizations.of(context)!;
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
              padding: const EdgeInsets.fromLTRB(AppSpacing.s18, AppSpacing.s10, AppSpacing.s18, AppSpacing.s6),
              itemCount: listings.length,
              separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.s14),
              itemBuilder: (context, index) {
                final listing = listings[index];
                return ListingCard(listing: listing, onTap: () => context.push('/listing/${listing.id}'));
              },
            ),
    );
  }
}

/// Search-bar-height button opening the filter sheet, badged with how many
/// filters are currently on so the header still says what's being hidden.
class _FilterButton extends StatelessWidget {
  final int activeCount;
  /// Null until the feed has loaded — filtering nothing would just show a
  /// "No results" count that isn't true yet.
  final VoidCallback? onTap;

  const _FilterButton({required this.activeCount, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final active = activeCount > 0;
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: active ? AppColors.nileGreen : AppColors.sandy,
              borderRadius: BorderRadius.circular(AppRadii.r14),
            ),
            child: Icon(
              Icons.tune,
              size: 20,
              color: active ? Colors.white : AppColors.inkAlpha(onTap == null ? 0.25 : 0.6),
            ),
          ),
          if (active)
            PositionedDirectional(
              top: -4,
              end: -4,
              child: Container(
                width: 18,
                height: 18,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.gold,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 1.5),
                ),
                child: Text('$activeCount', style: AppFonts.tajawal(size: 10, weight: FontWeight.w700, color: Colors.white)),
              ),
            ),
        ],
      ),
    );
  }
}

/// "12 listings" plus a one-tap escape hatch back to the unfiltered feed.
class _ResultsBar extends StatelessWidget {
  final int count;
  final bool showClear;
  final VoidCallback onClear;

  const _ResultsBar({required this.count, required this.showClear, required this.onClear});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.s18, AppSpacing.s12, AppSpacing.s18, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(l10n.listingsCount(count), style: AppFonts.tajawal(size: 12, weight: FontWeight.w600, color: AppColors.inkAlpha(0.6))),
          if (showClear)
            GestureDetector(
              onTap: onClear,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(l10n.clearFilters, style: AppFonts.tajawal(size: 12, weight: FontWeight.w700, color: AppColors.gold)),
                  const SizedBox(width: AppSpacing.s4),
                  const Icon(Icons.close, size: 14, color: AppColors.gold),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
