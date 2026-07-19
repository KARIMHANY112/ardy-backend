import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../models/buy_request.dart';
import '../../models/listing.dart';
import '../../services/api_client.dart';
import '../../services/listings_repository.dart';
import '../../state/auth_session.dart';
import '../../theme/app_theme.dart';
import '../../theme/app_dimens.dart';

class OwnerDashboardScreen extends StatefulWidget {
  const OwnerDashboardScreen({super.key});

  @override
  State<OwnerDashboardScreen> createState() => _OwnerDashboardScreenState();
}

class _OwnerDashboardScreenState extends State<OwnerDashboardScreen> {
  late Future<List<Listing>> _liveFuture;
  late Future<List<BuyRequest>> _buyRequestsFuture;
  late Future<List<Listing>> _papersPendingFuture;
  final Set<String> _busyIds = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    final repo = context.read<ListingsRepository>();
    _liveFuture = repo.browse();
    _buyRequestsFuture = repo.dashboardBuyRequests();
    _papersPendingFuture = repo.dashboardPapersPending();
  }

  Future<void> _callBuyer(String phone) async {
    await launchUrl(Uri.parse('tel:$phone'));
  }

  Future<void> _whatsAppBuyer(String phone, String listingTitle) async {
    final digits = phone.replaceAll(RegExp(r'\D'), '');
    final intl = digits.startsWith('0') ? '20${digits.substring(1)}' : digits;
    final text = Uri.encodeComponent("Hi, following up on your interest in $listingTitle");
    await launchUrl(Uri.parse('https://wa.me/$intl?text=$text'), mode: LaunchMode.externalApplication);
  }

  Future<void> _reviewBuyRequest(String requestId, {required bool approve}) async {
    setState(() => _busyIds.add(requestId));
    try {
      await context.read<ListingsRepository>().reviewBuyRequest(requestId, approve: approve);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(approve ? 'Papers pending for this buyer' : 'Buy request rejected')),
      );
      setState(_load);
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _busyIds.remove(requestId));
    }
  }

  Future<void> _finalizeSale(String listingId) async {
    setState(() => _busyIds.add(listingId));
    try {
      await context.read<ListingsRepository>().finalizeSale(listingId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Sale finalized')));
      setState(_load);
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _busyIds.remove(listingId));
    }
  }

  Future<void> _revertToLive(String listingId) async {
    setState(() => _busyIds.add(listingId));
    try {
      await context.read<ListingsRepository>().revertToLive(listingId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Listing back on the market')));
      setState(_load);
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _busyIds.remove(listingId));
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Owner Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await context.read<AuthSession>().logout();
              if (context.mounted) context.go('/login');
            },
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            setState(_load);
            await Future.wait([_liveFuture, _buyRequestsFuture, _papersPendingFuture]);
          },
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.s16),
            children: [
              FutureBuilder<List<Listing>>(
                future: _liveFuture,
                builder: (context, snapshot) => _StatCard(label: 'Live Listings', value: snapshot.hasData ? '${snapshot.data!.length}' : '—'),
              ),
              const SizedBox(height: AppSpacing.s24),
              Text('Buy Requests', style: textTheme.titleLarge),
              const SizedBox(height: AppSpacing.s12),
              FutureBuilder<List<BuyRequest>>(
                future: _buyRequestsFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState != ConnectionState.done) {
                    return const Padding(padding: EdgeInsets.symmetric(vertical: AppSpacing.s16), child: Center(child: CircularProgressIndicator()));
                  }
                  if (snapshot.hasError) {
                    final message = snapshot.error is ApiException ? (snapshot.error as ApiException).message : 'Could not load buy requests';
                    return Text(message, style: textTheme.bodyMedium?.copyWith(color: AppColors.ink.withValues(alpha: 0.6)));
                  }
                  final requests = snapshot.data!;
                  if (requests.isEmpty) {
                    return Text('No buy requests awaiting review', style: textTheme.bodyMedium?.copyWith(color: AppColors.ink.withValues(alpha: 0.6)));
                  }
                  return Column(
                    children: [
                      for (final request in requests)
                        Card(
                          margin: const EdgeInsets.only(bottom: AppSpacing.s10),
                          child: Padding(
                            padding: const EdgeInsets.all(AppSpacing.s14),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(request.listing.title, style: textTheme.titleMedium),
                                const SizedBox(height: AppSpacing.s4),
                                Text(
                                  '${request.buyerName} · ${request.buyerPhone}',
                                  style: textTheme.bodyMedium?.copyWith(color: AppColors.ink.withValues(alpha: 0.6)),
                                ),
                                const SizedBox(height: AppSpacing.s12),
                                Row(
                                  children: [
                                    Expanded(
                                      child: OutlinedButton(
                                        onPressed: () => _callBuyer(request.buyerPhone!),
                                        child: const Text('Call'),
                                      ),
                                    ),
                                    const SizedBox(width: AppSpacing.s12),
                                    Expanded(
                                      child: OutlinedButton(
                                        onPressed: () => _whatsAppBuyer(request.buyerPhone!, request.listing.title),
                                        child: const Text('WhatsApp'),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: AppSpacing.s8),
                                Row(
                                  children: [
                                    Expanded(
                                      child: OutlinedButton(
                                        onPressed: _busyIds.contains(request.id) ? null : () => _reviewBuyRequest(request.id, approve: false),
                                        child: const Text('Reject'),
                                      ),
                                    ),
                                    const SizedBox(width: AppSpacing.s12),
                                    Expanded(
                                      child: ElevatedButton(
                                        onPressed: _busyIds.contains(request.id) ? null : () => _reviewBuyRequest(request.id, approve: true),
                                        child: const Text('Approve (papers pending)'),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
              const SizedBox(height: AppSpacing.s24),
              Text('Papers Pending', style: textTheme.titleLarge),
              const SizedBox(height: AppSpacing.s12),
              FutureBuilder<List<Listing>>(
                future: _papersPendingFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState != ConnectionState.done) {
                    return const Padding(padding: EdgeInsets.symmetric(vertical: AppSpacing.s16), child: Center(child: CircularProgressIndicator()));
                  }
                  if (snapshot.hasError) {
                    final message = snapshot.error is ApiException ? (snapshot.error as ApiException).message : 'Could not load papers-pending listings';
                    return Text(message, style: textTheme.bodyMedium?.copyWith(color: AppColors.ink.withValues(alpha: 0.6)));
                  }
                  final listings = snapshot.data!;
                  if (listings.isEmpty) {
                    return Text('No sales awaiting paperwork', style: textTheme.bodyMedium?.copyWith(color: AppColors.ink.withValues(alpha: 0.6)));
                  }
                  return Column(
                    children: [
                      for (final listing in listings)
                        Card(
                          margin: const EdgeInsets.only(bottom: AppSpacing.s10),
                          child: Padding(
                            padding: const EdgeInsets.all(AppSpacing.s14),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(listing.title, style: textTheme.titleMedium),
                                const SizedBox(height: AppSpacing.s4),
                                Text(
                                  'Buyer: ${listing.soldToName ?? '—'} · ${listing.soldToPhone ?? '—'}',
                                  style: textTheme.bodyMedium?.copyWith(color: AppColors.ink.withValues(alpha: 0.6)),
                                ),
                                const SizedBox(height: AppSpacing.s12),
                                Row(
                                  children: [
                                    Expanded(
                                      child: OutlinedButton(
                                        onPressed: _busyIds.contains(listing.id) ? null : () => _revertToLive(listing.id),
                                        child: const Text('Deal Fell Through'),
                                      ),
                                    ),
                                    const SizedBox(width: AppSpacing.s12),
                                    Expanded(
                                      child: ElevatedButton(
                                        onPressed: _busyIds.contains(listing.id) ? null : () => _finalizeSale(listing.id),
                                        child: const Text('Finalize Sale'),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
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
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;

  const _StatCard({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.s16, horizontal: AppSpacing.s12),
        child: Column(
          children: [
            Text(value, style: textTheme.headlineMedium?.copyWith(color: AppColors.nileGreen)),
            const SizedBox(height: AppSpacing.s4),
            Text(label, textAlign: TextAlign.center, style: textTheme.bodyMedium?.copyWith(fontSize: 12)),
          ],
        ),
      ),
    );
  }
}
