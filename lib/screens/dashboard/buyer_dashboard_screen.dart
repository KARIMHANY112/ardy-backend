import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../l10n/generated/app_localizations.dart';
import '../../models/buy_request.dart';
import '../../models/listing.dart';
import '../../services/listings_repository.dart';
import '../../state/auth_session.dart';
import '../../theme/app_theme.dart';
import '../../theme/app_dimens.dart';
import '../../widgets/dashboard_link_card.dart';

class BuyerDashboardScreen extends StatefulWidget {
  const BuyerDashboardScreen({super.key});

  @override
  State<BuyerDashboardScreen> createState() => _BuyerDashboardScreenState();
}

class _BuyerDashboardScreenState extends State<BuyerDashboardScreen> {
  late Future<List<Listing>> _myListingsFuture;
  late Future<List<BuyRequest>> _myBuyRequestsFuture;

  @override
  void initState() {
    super.initState();
    final repo = context.read<ListingsRepository>();
    _myListingsFuture = repo.myRequests();
    _myBuyRequestsFuture = repo.myBuyRequests();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final textTheme = Theme.of(context).textTheme;
    final user = context.watch<AuthSession>().user;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.dashboardTitle)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.s16),
          children: [
            Text('${l10n.welcomeBack}${user != null ? ', ${user.name}' : ''}', style: textTheme.headlineMedium),
            const SizedBox(height: AppSpacing.s4),
            Text(
              l10n.browseChatPostSubtitle,
              style: textTheme.bodyMedium?.copyWith(color: AppColors.ink.withValues(alpha: 0.6)),
            ),
            const SizedBox(height: AppSpacing.s20),
            DashboardLinkCard(
              icon: Icons.home_outlined,
              title: l10n.browseListings,
              subtitle: l10n.browseListingsSubtitle,
              onTap: () => context.go('/home'),
            ),
            const SizedBox(height: AppSpacing.s12),
            DashboardLinkCard(
              icon: Icons.chat_bubble_outline,
              title: l10n.landAdvisorTitle,
              subtitle: l10n.landAdvisorCardSubtitle,
              onTap: () => context.go('/advisor'),
            ),
            const SizedBox(height: AppSpacing.s12),
            DashboardLinkCard(
              icon: Icons.favorite_border,
              title: l10n.favoritesTitle,
              subtitle: l10n.favoritesCardSubtitle,
              onTap: () => context.go('/favorites'),
            ),
            const SizedBox(height: AppSpacing.s12),
            DashboardLinkCard(
              icon: Icons.person_outline,
              title: l10n.profileTitle,
              subtitle: l10n.profileCardSubtitle,
              onTap: () => context.go('/profile'),
            ),
            const SizedBox(height: AppSpacing.s20),
            Text(l10n.myListings, style: textTheme.titleLarge),
            const SizedBox(height: AppSpacing.s12),
            FutureBuilder<List<Listing>>(
              future: _myListingsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const Padding(padding: EdgeInsets.symmetric(vertical: AppSpacing.s16), child: Center(child: CircularProgressIndicator()));
                }
                if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
                  return Text(
                    l10n.noListingsSubmittedYet,
                    style: textTheme.bodyMedium?.copyWith(color: AppColors.ink.withValues(alpha: 0.6)),
                  );
                }
                return Column(
                  children: [
                    for (final listing in snapshot.data!)
                      Card(
                        margin: const EdgeInsets.only(bottom: AppSpacing.s10),
                        child: ListTile(
                          leading: const CircleAvatar(backgroundColor: AppColors.sandy, child: Icon(Icons.photo_outlined, color: AppColors.divider)),
                          title: Text(listing.title),
                          subtitle: Text('${listing.offerType.label(context)} · ${listing.category.label(context)} · ${listing.location}'),
                          trailing: _StatusPill(status: listing.status),
                          onTap: listing.status == ListingStatus.live
                              ? () => context.push('/listing/${listing.id}')
                              : () => ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text(l10n.listingStillStatusMessage(listing.title, listing.status.label(context).toLowerCase()))),
                                  ),
                        ),
                      ),
                  ],
                );
              },
            ),
            const SizedBox(height: AppSpacing.s20),
            Text(l10n.myBuyRequests, style: textTheme.titleLarge),
            const SizedBox(height: AppSpacing.s12),
            FutureBuilder<List<BuyRequest>>(
              future: _myBuyRequestsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const Padding(padding: EdgeInsets.symmetric(vertical: AppSpacing.s16), child: Center(child: CircularProgressIndicator()));
                }
                if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
                  return Text(
                    l10n.noBuyRequestsYet,
                    style: textTheme.bodyMedium?.copyWith(color: AppColors.ink.withValues(alpha: 0.6)),
                  );
                }
                return Column(
                  children: [
                    for (final request in snapshot.data!)
                      Card(
                        margin: const EdgeInsets.only(bottom: AppSpacing.s10),
                        child: ListTile(
                          leading: const CircleAvatar(backgroundColor: AppColors.sandy, child: Icon(Icons.request_quote_outlined, color: AppColors.divider)),
                          title: Text(request.listing.title),
                          subtitle: Text('${request.listing.offerType.label(context)} · ${request.listing.category.label(context)} · ${request.listing.location}'),
                          trailing: _BuyRequestStatusPill(request: request),
                          onTap: request.listing.status == ListingStatus.live
                              ? () => context.push('/listing/${request.listing.id}')
                              : () => ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text(l10n.listingStatusMessage(request.listing.title, request.listing.status.label(context).toLowerCase()))),
                                  ),
                        ),
                      ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final ListingStatus status;

  const _StatusPill({required this.status});

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      ListingStatus.live => AppColors.nileGreen,
      ListingStatus.pending => AppColors.gold,
      ListingStatus.papersPending => AppColors.pendingAmber,
      ListingStatus.rejected => Colors.redAccent,
      ListingStatus.sold => AppColors.ink,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s10, vertical: AppSpacing.s4),
      decoration: BoxDecoration(color: AppColors.sandy, borderRadius: BorderRadius.circular(AppRadii.r20)),
      child: Text(status.label(context), style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 12, color: color)),
    );
  }
}

class _BuyRequestStatusPill extends StatelessWidget {
  final BuyRequest request;

  const _BuyRequestStatusPill({required this.request});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    // BuyRequestStatus.approved only means the deal reached papers-pending — it
    // doesn't flip to anything else once the listing itself is finalized, so the
    // displayed label has to come from the listing's current status instead.
    final (label, color) = switch (request.status) {
      BuyRequestStatus.pending => (l10n.buyRequestStatusRequested, AppColors.gold),
      BuyRequestStatus.rejected => (l10n.statusRejected, Colors.redAccent),
      // An approved request whose listing is back to live is stale — that deal fell
      // through (and reverting resets this properly now, but older data from before
      // that fix won't retroactively update, so it needs to still be handled here).
      BuyRequestStatus.approved => switch (request.listing.status) {
          ListingStatus.sold => (l10n.buyRequestStatusBought, AppColors.nileGreen),
          ListingStatus.papersPending => (l10n.statusPapersPending, AppColors.pendingAmber),
          _ => (l10n.buyRequestFellThrough, AppColors.inkAlpha(0.5)),
        },
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s10, vertical: AppSpacing.s4),
      decoration: BoxDecoration(color: AppColors.sandy, borderRadius: BorderRadius.circular(AppRadii.r20)),
      child: Text(label, style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 12, color: color)),
    );
  }
}
