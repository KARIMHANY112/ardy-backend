import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../l10n/generated/app_localizations.dart';
import '../../models/buy_request.dart';
import '../../models/listing.dart';
import '../../models/user.dart';
import '../../services/listings_repository.dart';
import '../../state/auth_session.dart';
import '../../state/locale_provider.dart';
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
  bool _deleting = false;

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

  /// Two-step by design: account deletion is irreversible and also takes down any
  /// listings the user posted, so it must never be one stray tap away.
  Future<void> _confirmDeleteAccount() async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.deleteAccountTitle, style: AppFonts.cairo(size: 17, weight: FontWeight.w700)),
        content: Text(l10n.deleteAccountWarning, style: AppFonts.tajawal(size: 13, weight: FontWeight.w400)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.deleteAccountCancel, style: AppFonts.tajawal(size: 13, weight: FontWeight.w700, color: AppColors.ink)),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l10n.deleteAccountConfirm, style: AppFonts.tajawal(size: 13, weight: FontWeight.w700, color: Colors.redAccent)),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _deleting = true);
    try {
      await context.read<AuthSession>().deleteAccount();
      if (mounted) context.go('/login');
    } catch (error) {
      if (!mounted) return;
      setState(() => _deleting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.deleteAccountFailed(error.toString()))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final user = context.watch<AuthSession>().user;

    return AppBottomNavScaffold(
      currentIndex: 3,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          BrandHeader(title: l10n.profileTitle, titleSize: 22),
          Container(
            color: Colors.white,
            child: TabBar(
              controller: _tabController,
              labelColor: AppColors.nileGreen,
              unselectedLabelColor: AppColors.inkAlpha(0.5),
              indicatorColor: AppColors.nileGreen,
              labelStyle: AppFonts.tajawal(size: 13, weight: FontWeight.w700),
              unselectedLabelStyle: AppFonts.tajawal(size: 13, weight: FontWeight.w600),
              tabs: [
                Tab(text: l10n.profileTitle),
                Tab(text: l10n.boughtTab),
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
    final l10n = AppLocalizations.of(context)!;
    final localeProvider = context.watch<LocaleProvider>();
    final currentLanguageCode = localeProvider.locale?.languageCode ?? Localizations.localeOf(context).languageCode;

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
                    Text(user?.name ?? 'Ardi User', style: AppFonts.cairo(size: 15, weight: FontWeight.w700)),
                    Text(user?.email ?? '', style: AppFonts.tajawal(size: 13, weight: FontWeight.w400, color: AppColors.inkAlpha(0.6))),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.s16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s16, vertical: AppSpacing.s10),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(AppRadii.r18), boxShadow: AppColors.cardShadow),
            child: Row(
              children: [
                Expanded(
                  child: Text(l10n.languageLabel, style: AppFonts.tajawal(size: 14, weight: FontWeight.w600, color: AppColors.ink)),
                ),
                SegmentedButton<String>(
                  segments: [
                    ButtonSegment(value: 'en', label: Text(l10n.englishLanguageName)),
                    ButtonSegment(value: 'ar', label: Text(l10n.arabicLanguageName)),
                  ],
                  selected: {currentLanguageCode},
                  onSelectionChanged: (selection) => context.read<LocaleProvider>().setLocale(Locale(selection.first)),
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
                  Text(l10n.logOut, style: AppFonts.tajawal(size: 14, weight: FontWeight.w700, color: AppColors.nileGreen)),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.s10),
          // Play requires an in-app deletion path for any app with accounts, and
          // the Privacy Policy promises one. Styled destructively and kept last.
          GestureDetector(
            onTap: _deleting ? null : _confirmDeleteAccount,
            child: Container(
              height: 48,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(AppRadii.r14),
                border: Border.all(color: Colors.redAccent, width: 1.5),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (_deleting)
                    const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.redAccent))
                  else
                    const Icon(Icons.delete_outline, color: Colors.redAccent, size: 18),
                  const SizedBox(width: AppSpacing.s8),
                  Text(l10n.deleteAccount, style: AppFonts.tajawal(size: 14, weight: FontWeight.w700, color: Colors.redAccent)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBoughtTab(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return FutureBuilder<List<BuyRequest>>(
      future: _boughtFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(
            child: Text(
              l10n.haventBoughtAnythingYet,
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
                        child: Text(l10n.boughtBadge, style: AppFonts.tajawal(size: 12, weight: FontWeight.w700, color: AppColors.nileGreen)),
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
