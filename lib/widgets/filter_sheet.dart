import 'package:flutter/material.dart';

import '../l10n/generated/app_localizations.dart';
import '../models/listing.dart';
import '../theme/app_theme.dart';
import '../theme/app_dimens.dart';
import 'category_pill.dart';

/// The two filters the Home Feed applies on top of the search query. Both null
/// means "show everything".
class ListingFilters {
  final ListingCategory? category;
  final OfferType? offerType;

  const ListingFilters({this.category, this.offerType});

  bool get isEmpty => category == null && offerType == null;

  /// How many filters are active — drives the badge on the header's filter button.
  int get activeCount => (category == null ? 0 : 1) + (offerType == null ? 0 : 1);

  bool matches(Listing listing) =>
      (category == null || listing.category == category) && (offerType == null || listing.offerType == offerType);

  ListingFilters copyWith({ListingCategory? category, OfferType? offerType, bool clearCategory = false, bool clearOfferType = false}) =>
      ListingFilters(
        category: clearCategory ? null : (category ?? this.category),
        offerType: clearOfferType ? null : (offerType ?? this.offerType),
      );
}

/// Bottom sheet holding every listing filter. Selections are a draft until
/// "Show N results" is tapped, so a mis-tap never reshuffles the feed underneath
/// the user — dismissing the sheet discards them.
///
/// Returns the chosen [ListingFilters], or null if dismissed.
Future<ListingFilters?> showListingFilterSheet(
  BuildContext context, {
  required ListingFilters current,
  required int Function(ListingFilters) countMatches,
}) =>
    showModalBottomSheet<ListingFilters>(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadii.r18)),
      ),
      builder: (context) => _FilterSheet(initial: current, countMatches: countMatches),
    );

class _FilterSheet extends StatefulWidget {
  final ListingFilters initial;
  final int Function(ListingFilters) countMatches;

  const _FilterSheet({required this.initial, required this.countMatches});

  @override
  State<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<_FilterSheet> {
  late ListingFilters _draft = widget.initial;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    // Plural filter-chip copy ("Factories"), matching the design handoff — the
    // singular ListingCategory.label is used for one specific listing.
    final categoryLabels = {
      ListingCategory.factory: l10n.filterFactories,
      ListingCategory.land: l10n.filterLand,
      ListingCategory.shop: l10n.filterShops,
    };
    final resultCount = widget.countMatches(_draft);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(AppSpacing.s18, AppSpacing.s10, AppSpacing.s18, AppSpacing.s18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(color: AppColors.divider, borderRadius: BorderRadius.circular(AppRadii.pill)),
              ),
            ),
            const SizedBox(height: AppSpacing.s16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(l10n.filtersTitle, style: AppFonts.cairo(size: 16, weight: FontWeight.w700)),
                GestureDetector(
                  onTap: _draft.isEmpty ? null : () => setState(() => _draft = const ListingFilters()),
                  child: Text(
                    l10n.resetFilters,
                    style: AppFonts.tajawal(
                      size: 13,
                      weight: FontWeight.w700,
                      color: _draft.isEmpty ? AppColors.inkAlpha(0.35) : AppColors.gold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.s16),
            _SectionLabel(l10n.offerSectionLabel),
            Wrap(
              spacing: AppSpacing.s8,
              runSpacing: AppSpacing.s8,
              children: [
                CategoryPill(
                  label: l10n.filterAll,
                  selected: _draft.offerType == null,
                  onTap: () => setState(() => _draft = _draft.copyWith(clearOfferType: true)),
                ),
                for (final offerType in OfferType.values)
                  CategoryPill(
                    label: offerType.label(context),
                    selected: _draft.offerType == offerType,
                    onTap: () => setState(() => _draft = _draft.copyWith(offerType: offerType)),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.s20),
            _SectionLabel(l10n.categoryLabel),
            Wrap(
              spacing: AppSpacing.s8,
              runSpacing: AppSpacing.s8,
              children: [
                CategoryPill(
                  label: l10n.filterAll,
                  selected: _draft.category == null,
                  onTap: () => setState(() => _draft = _draft.copyWith(clearCategory: true)),
                ),
                for (final category in ListingCategory.values)
                  CategoryPill(
                    label: categoryLabels[category]!,
                    selected: _draft.category == category,
                    onTap: () => setState(() => _draft = _draft.copyWith(category: category)),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.s24),
            GestureDetector(
              onTap: () => Navigator.of(context).pop(_draft),
              child: Container(
                height: 48,
                width: double.infinity,
                alignment: Alignment.center,
                decoration: BoxDecoration(color: AppColors.nileGreen, borderRadius: BorderRadius.circular(AppRadii.r14)),
                child: Text(
                  l10n.showResults(resultCount),
                  style: AppFonts.tajawal(size: 14, weight: FontWeight.w700, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;

  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.s10),
        child: Text(text, style: AppFonts.cairo(size: 13, weight: FontWeight.w700)),
      );
}
