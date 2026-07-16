import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../models/listing.dart';
import '../../services/api_client.dart';
import '../../services/favorites_repository.dart';
import '../../services/listings_repository.dart';
import '../../theme/app_theme.dart';
import '../../utils/formatters.dart';
import '../../widgets/agent_info_card.dart';
import '../../widgets/detail_cta_bar.dart';
import '../../widgets/listing_fact_cell.dart';
import '../../widgets/listing_gallery_header.dart';
import '../../widgets/tag_badge.dart';

/// Listing Detail — direction 1a: rounded white sheet, 2x2 sand-bg fact
/// cells, outline "Call" + filled nile "WhatsApp" buttons.
class ListingDetailScreen extends StatefulWidget {
  final String listingId;
  // Pass this in (e.g. from a Bought/My Listings card) to skip the network
  // fetch — useful for non-live listings, which GET /listings/{id} 404s on.
  final Listing? initialListing;

  const ListingDetailScreen({super.key, required this.listingId, this.initialListing});

  @override
  State<ListingDetailScreen> createState() => _ListingDetailScreenState();
}

class _ListingDetailScreenState extends State<ListingDetailScreen> {
  // The single contact number for arranging a deal — same number for every
  // listing regardless of who submitted it.
  static const _contactPhone = '01282092054';
  static const _contactPhoneIntl = '201282092054'; // wa.me needs intl format, no leading 0

  late Future<Listing> _listingFuture;
  bool _isFavorite = false;
  bool _favoriteBusy = false;
  bool _hasRequestedBuy = false;

  @override
  void initState() {
    super.initState();
    _listingFuture = _load();
  }

  Future<Listing> _load() async {
    final listingsRepo = context.read<ListingsRepository>();
    final favoritesRepo = context.read<FavoritesRepository>();

    final listing = widget.initialListing ?? await listingsRepo.getById(widget.listingId);
    if (listing.status != ListingStatus.live) {
      // Favoriting/buy-requesting only applies to live listings — nothing more to load.
      return listing;
    }
    try {
      final favorites = await favoritesRepo.list();
      _isFavorite = favorites.any((f) => f.listing.id == widget.listingId);
    } catch (_) {
      // Favorite status is a nice-to-have on this screen — don't block the listing on it.
    }
    try {
      final buyRequests = await listingsRepo.myBuyRequests();
      _hasRequestedBuy = buyRequests.any((r) => r.listing.id == widget.listingId);
    } catch (_) {
      // Same — don't block the listing render on this.
    }
    return listing;
  }

  Future<void> _requestToBuy() async {
    try {
      await context.read<ListingsRepository>().requestToBuy(widget.listingId);
      if (!mounted) return;
      setState(() => _hasRequestedBuy = true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Request sent — call or WhatsApp to arrange the deal')),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  Future<void> _call() async {
    await launchUrl(Uri.parse('tel:$_contactPhone'));
  }

  Future<void> _openInGoogleMaps(Listing listing) async {
    if (!listing.hasCoordinates) return;
    final query = '${listing.latitude},${listing.longitude}';
    await launchUrl(Uri.parse('https://www.google.com/maps/search/?api=1&query=$query'), mode: LaunchMode.externalApplication);
  }

  Future<void> _openWhatsApp(Listing listing) async {
    final text = Uri.encodeComponent("Hi, I'm interested in listing ${listing.refCode} — ${listing.title}");
    await launchUrl(Uri.parse('https://wa.me/$_contactPhoneIntl?text=$text'), mode: LaunchMode.externalApplication);
  }

  Future<void> _toggleFavorite() async {
    setState(() => _favoriteBusy = true);
    final favorites = context.read<FavoritesRepository>();
    try {
      if (_isFavorite) {
        await favorites.remove(widget.listingId);
      } else {
        await favorites.add(widget.listingId);
      }
      setState(() => _isFavorite = !_isFavorite);
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _favoriteBusy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        bottom: false,
        child: FutureBuilder<Listing>(
          future: _listingFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              final message = snapshot.error is ApiException ? (snapshot.error as ApiException).message : 'Could not load this listing';
              return Center(child: Text(message, style: AppFonts.tajawal(size: 14, weight: FontWeight.w400, color: AppColors.inkAlpha(0.6))));
            }
            final listing = snapshot.data!;
            return _buildBody(context, listing);
          },
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context, Listing listing) {
    return Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ListingGalleryHeader(
                      isFavorite: _isFavorite,
                      onBack: () => context.pop(),
                      onToggleFavorite: _favoriteBusy ? () {} : _toggleFavorite,
                      photoUrls: listing.photoUrls,
                    ),
                    Padding(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          TagBadge(text: listing.category.label.toUpperCase(), color: AppColors.deepGreen),
                          const SizedBox(height: 8),
                          Text(listing.title, style: AppFonts.cairo(size: 20, weight: FontWeight.w700)),
                          const SizedBox(height: 4),
                          Text(listing.location, style: AppFonts.tajawal(size: 13, weight: FontWeight.w400, color: AppColors.inkAlpha(0.6))),
                          const SizedBox(height: 16),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            children: [
                              Text(formatEgp(listing.price), style: AppFonts.cairo(size: 26, weight: FontWeight.w800, color: AppColors.gold)),
                              if (listing.sizeSqm > 0) ...[
                                const SizedBox(width: 8),
                                Text(
                                  '${formatEgp((listing.price / listing.sizeSqm).round())}/sqm',
                                  style: AppFonts.tajawal(size: 13, weight: FontWeight.w400, color: AppColors.inkAlpha(0.6)),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 16),
                          const Divider(height: 1, color: AppColors.divider),
                          const SizedBox(height: 16),
                          GridView.count(
                            crossAxisCount: 2,
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            mainAxisSpacing: 10,
                            crossAxisSpacing: 10,
                            childAspectRatio: 2.6,
                            children: [
                              ListingFactCell(label: 'Area', value: formatSqm(listing.sizeSqm)),
                              ListingFactCell(label: 'License', value: listing.license.label),
                              ListingFactCell(label: 'Type', value: listing.category.label),
                              // No "built year" field on the backend yet — ref code fills the
                              // fourth cell the design reserves for that fact.
                              ListingFactCell(label: 'Ref Code', value: listing.refCode),
                            ],
                          ),
                          const SizedBox(height: 20),
                          Text('Description', style: AppFonts.cairo(size: 14, weight: FontWeight.w700)),
                          const SizedBox(height: 6),
                          Text(listing.description, style: AppFonts.tajawal(size: 13, weight: FontWeight.w400, color: AppColors.ink, height: 1.6)),
                          const SizedBox(height: 20),
                          Text('Location', style: AppFonts.cairo(size: 14, weight: FontWeight.w700)),
                          const SizedBox(height: 6),
                          if (listing.hasCoordinates) ...[
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: SizedBox(
                                height: 160,
                                width: double.infinity,
                                child: GoogleMap(
                                  initialCameraPosition: CameraPosition(
                                    target: LatLng(listing.latitude!, listing.longitude!),
                                    zoom: 14,
                                  ),
                                  markers: {
                                    Marker(markerId: const MarkerId('listing'), position: LatLng(listing.latitude!, listing.longitude!)),
                                  },
                                  zoomControlsEnabled: false,
                                  scrollGesturesEnabled: false,
                                  rotateGesturesEnabled: false,
                                  tiltGesturesEnabled: false,
                                  onTap: (_) => _openInGoogleMaps(listing),
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            GestureDetector(
                              onTap: () => _openInGoogleMaps(listing),
                              child: Text(
                                'Open in Google Maps',
                                style: AppFonts.tajawal(size: 13, weight: FontWeight.w700, color: AppColors.gold),
                              ),
                            ),
                          ] else
                            Container(
                              height: 130,
                              width: double.infinity,
                              decoration: BoxDecoration(color: AppColors.sandy, borderRadius: BorderRadius.circular(12)),
                              child: const Center(child: Icon(Icons.map_outlined, color: AppColors.divider, size: 32)),
                            ),
                          const SizedBox(height: 16),
                          const AgentInfoCard(name: 'Mostafa Adel', subtitle: 'Listing agent · ARDI verified'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (listing.status == ListingStatus.live)
              DetailCtaBar(
                isFavorite: _isFavorite,
                hasRequestedBuy: _hasRequestedBuy,
                onToggleFavorite: _favoriteBusy ? () {} : _toggleFavorite,
                onRequestBuy: _requestToBuy,
                onCall: _call,
                onWhatsApp: () => _openWhatsApp(listing),
              )
            else
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(18, 14, 18, 16),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  border: Border(top: BorderSide(color: AppColors.divider)),
                ),
                child: Text(
                  'This listing has been sold',
                  textAlign: TextAlign.center,
                  style: AppFonts.tajawal(size: 14, weight: FontWeight.w700, color: AppColors.ink),
                ),
              ),
          ],
        );
  }
}
