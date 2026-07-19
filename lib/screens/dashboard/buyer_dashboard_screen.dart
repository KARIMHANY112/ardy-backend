import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../models/buy_request.dart';
import '../../models/listing.dart';
import '../../models/user.dart';
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
    final textTheme = Theme.of(context).textTheme;
    final user = context.watch<AuthSession>().user;

    return Scaffold(
      appBar: AppBar(title: const Text('Dashboard')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.s16),
          children: [
            Text('Welcome back${user != null ? ', ${user.name}' : ''}', style: textTheme.headlineMedium),
            const SizedBox(height: AppSpacing.s4),
            Text(
              'Browse listings, chat with the Land Advisor, or post one of your own.',
              style: textTheme.bodyMedium?.copyWith(color: AppColors.ink.withValues(alpha: 0.6)),
            ),
            if (user?.status == AccountStatus.pending) ...[
              const SizedBox(height: AppSpacing.s12),
              Container(
                padding: const EdgeInsets.all(AppSpacing.s12),
                decoration: BoxDecoration(color: AppColors.sandy, borderRadius: BorderRadius.circular(AppRadii.r12)),
                child: Text(
                  'Your account is pending owner approval — you can browse and favorite, but posting a listing is locked until then.',
                  style: textTheme.bodyMedium?.copyWith(fontSize: 12, color: AppColors.ink.withValues(alpha: 0.7)),
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.s20),
            DashboardLinkCard(
              icon: Icons.home_outlined,
              title: 'Browse Listings',
              subtitle: 'Search factories, land, and shops',
              onTap: () => context.go('/home'),
            ),
            const SizedBox(height: AppSpacing.s12),
            DashboardLinkCard(
              icon: Icons.add_box_outlined,
              title: 'Post New Listing',
              subtitle: 'List a factory, land, or shop',
              onTap: () => context.go('/post-listing'),
            ),
            const SizedBox(height: AppSpacing.s12),
            DashboardLinkCard(
              icon: Icons.chat_bubble_outline,
              title: 'Land Advisor',
              subtitle: 'Get AI-matched recommendations',
              onTap: () => context.go('/advisor'),
            ),
            const SizedBox(height: AppSpacing.s12),
            DashboardLinkCard(
              icon: Icons.favorite_border,
              title: 'Favorites',
              subtitle: 'View your saved listings',
              onTap: () => context.go('/favorites'),
            ),
            const SizedBox(height: AppSpacing.s12),
            DashboardLinkCard(
              icon: Icons.person_outline,
              title: 'Profile',
              subtitle: 'Account settings',
              onTap: () => context.go('/profile'),
            ),
            const SizedBox(height: AppSpacing.s20),
            Text('My Listings', style: textTheme.titleLarge),
            const SizedBox(height: AppSpacing.s12),
            FutureBuilder<List<Listing>>(
              future: _myListingsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const Padding(padding: EdgeInsets.symmetric(vertical: AppSpacing.s16), child: Center(child: CircularProgressIndicator()));
                }
                if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
                  return Text(
                    'No listings submitted yet',
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
                          subtitle: Text('${listing.category.label} · ${listing.location}'),
                          trailing: _StatusPill(status: listing.status),
                          onTap: listing.status == ListingStatus.live
                              ? () => context.push('/listing/${listing.id}')
                              : () => ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('${listing.title} is still ${listing.status.label.toLowerCase()}')),
                                  ),
                        ),
                      ),
                  ],
                );
              },
            ),
            const SizedBox(height: AppSpacing.s20),
            Text('My Buy Requests', style: textTheme.titleLarge),
            const SizedBox(height: AppSpacing.s12),
            FutureBuilder<List<BuyRequest>>(
              future: _myBuyRequestsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const Padding(padding: EdgeInsets.symmetric(vertical: AppSpacing.s16), child: Center(child: CircularProgressIndicator()));
                }
                if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
                  return Text(
                    'No buy requests yet',
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
                          subtitle: Text('${request.listing.category.label} · ${request.listing.location}'),
                          trailing: _BuyRequestStatusPill(request: request),
                          onTap: request.listing.status == ListingStatus.live
                              ? () => context.push('/listing/${request.listing.id}')
                              : () => ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('${request.listing.title} is ${request.listing.status.label.toLowerCase()}')),
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
      child: Text(status.label, style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 12, color: color)),
    );
  }
}

class _BuyRequestStatusPill extends StatelessWidget {
  final BuyRequest request;

  const _BuyRequestStatusPill({required this.request});

  @override
  Widget build(BuildContext context) {
    // BuyRequestStatus.approved only means the deal reached papers-pending — it
    // doesn't flip to anything else once the listing itself is finalized, so the
    // displayed label has to come from the listing's current status instead.
    final (label, color) = switch (request.status) {
      BuyRequestStatus.pending => ('Requested', AppColors.gold),
      BuyRequestStatus.rejected => ('Rejected', Colors.redAccent),
      BuyRequestStatus.approved => switch (request.listing.status) {
          ListingStatus.sold => ('Bought', AppColors.nileGreen),
          _ => ('Papers Pending', AppColors.pendingAmber),
        },
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s10, vertical: AppSpacing.s4),
      decoration: BoxDecoration(color: AppColors.sandy, borderRadius: BorderRadius.circular(AppRadii.r20)),
      child: Text(label, style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 12, color: color)),
    );
  }
}
