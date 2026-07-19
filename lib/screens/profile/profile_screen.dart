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
import '../../widgets/app_bottom_nav.dart';
import '../../widgets/brand_header.dart';
import '../../widgets/listing_photo.dart';

/// Not one of the 7 design-handoff screens ("Profile — not mocked in this
/// batch"), restyled here to match the same header/card language as the rest
/// of the app.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  late Future<List<BuyRequest>> _boughtFuture;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    // Approval only means the deal moved to papers-pending — this tab should only
    // show purchases once the sale is fully finalized (listing.status == sold).
    _boughtFuture = context.read<ListingsRepository>().myBuyRequests().then(
          (requests) => requests.where((r) => r.status == BuyRequestStatus.approved && r.listing.status == ListingStatus.sold).toList(),
        );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthSession>().user;

    return AppBottomNavScaffold(
      currentIndex: 3,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const BrandHeader(title: 'Profile', titleSize: 22),
          Container(
            color: Colors.white,
            child: TabBar(
              controller: _tabController,
              labelColor: AppColors.nileGreen,
              unselectedLabelColor: AppColors.inkAlpha(0.5),
              indicatorColor: AppColors.nileGreen,
              labelStyle: AppFonts.tajawal(size: 13, weight: FontWeight.w700),
              unselectedLabelStyle: AppFonts.tajawal(size: 13, weight: FontWeight.w600),
              tabs: const [
                Tab(text: 'Profile'),
                Tab(text: 'Bought'),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildProfileTab(context, user),
                _buildBoughtTab(context),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileTab(BuildContext context, AppUser? user) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.s18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.s16),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(AppRadii.r18), boxShadow: AppColors.cardShadow),
            child: Row(
              children: [
                const CircleAvatar(radius: 28, backgroundColor: AppColors.sandy, child: Icon(Icons.person, color: AppColors.ink, size: 28)),
                const SizedBox(width: AppSpacing.s14),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(user?.name ?? 'Ardy User', style: AppFonts.cairo(size: 15, weight: FontWeight.w700)),
                    Text(user?.email ?? '', style: AppFonts.tajawal(size: 13, weight: FontWeight.w400, color: AppColors.inkAlpha(0.6))),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.s16),
          GestureDetector(
            onTap: () async {
              await context.read<AuthSession>().logout();
              if (context.mounted) context.go('/login');
            },
            child: Container(
              height: 48,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(AppRadii.r14),
                border: Border.all(color: AppColors.nileGreen, width: 1.5),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.logout, color: AppColors.nileGreen, size: 18),
                  const SizedBox(width: AppSpacing.s8),
                  Text('Log Out', style: AppFonts.tajawal(size: 14, weight: FontWeight.w700, color: AppColors.nileGreen)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBoughtTab(BuildContext context) {
    return FutureBuilder<List<BuyRequest>>(
      future: _boughtFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(
            child: Text(
              "You haven't bought anything yet",
              style: AppFonts.tajawal(size: 13, weight: FontWeight.w400, color: AppColors.inkAlpha(0.6)),
            ),
          );
        }
        return ListView(
          padding: const EdgeInsets.all(AppSpacing.s18),
          children: [
            for (final request in snapshot.data!)
              GestureDetector(
                onTap: () => context.push('/listing/${request.listing.id}', extra: request.listing),
                child: Container(
                  margin: const EdgeInsets.only(bottom: AppSpacing.s10),
                  padding: const EdgeInsets.all(AppSpacing.s14),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(AppRadii.r14), boxShadow: AppColors.cardShadow),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(AppRadii.r10),
                        child: SizedBox(
                          width: 56,
                          height: 56,
                          child: Container(
                            color: AppColors.sandy,
                            child: ListingPhoto(photoUrls: request.listing.photoUrls, iconSize: 24),
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.s12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(request.listing.title, style: AppFonts.cairo(size: 14, weight: FontWeight.w700)),
                            const SizedBox(height: AppSpacing.s2),
                            Text(
                              request.listing.location,
                              style: AppFonts.tajawal(size: 12, weight: FontWeight.w400, color: AppColors.inkAlpha(0.6)),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: AppSpacing.s8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s10, vertical: AppSpacing.s4),
                        decoration: BoxDecoration(color: AppColors.sandy, borderRadius: BorderRadius.circular(AppRadii.r20)),
                        child: Text('Bought', style: AppFonts.tajawal(size: 12, weight: FontWeight.w700, color: AppColors.nileGreen)),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
