import 'dart:typed_data';

import '../models/buy_request.dart';
import '../models/listing.dart';
import 'api_client.dart';

class ListingsRepository {
  ListingsRepository(this.api);

  final ApiClient api;

  /// Public browse — live listings only (GET /listings).
  Future<List<Listing>> browse() async {
    final data = await api.get('/listings') as List<dynamic>;
    return data.map((json) => Listing.fromJson(json as Map<String, dynamic>)).toList();
  }

  Future<Listing> getById(String id) async {
    final data = await api.get('/listings/$id');
    return Listing.fromJson(data as Map<String, dynamic>);
  }

  /// The current user's own submitted listing requests, any status (GET /listings/mine/requests).
  Future<List<Listing>> myRequests() async {
    final data = await api.get('/listings/mine/requests') as List<dynamic>;
    return data.map((json) => Listing.fromJson(json as Map<String, dynamic>)).toList();
  }

  /// Buyer expresses interest in a listing — idempotent, safe to call more than once.
  Future<BuyRequest> requestToBuy(String listingId) async {
    final data = await api.post('/listings/$listingId/buy-request');
    return BuyRequest.fromJson(data as Map<String, dynamic>);
  }

  /// The current buyer's own buy requests (GET /listings/mine/buy-requests).
  Future<List<BuyRequest>> myBuyRequests() async {
    final data = await api.get('/listings/mine/buy-requests') as List<dynamic>;
    return data.map((json) => BuyRequest.fromJson(json as Map<String, dynamic>)).toList();
  }

  Future<Listing> create({
    required String title,
    required ListingCategory category,
    required double price,
    required double size,
    required String location,
    String? description,
    double? latitude,
    double? longitude,
  }) async {
    final body = <String, dynamic>{
      'title': title,
      'type': category.name,
      'price': price,
      'size': size,
      'location': location,
    };
    if (description != null && description.isNotEmpty) body['description'] = description;
    if (latitude != null) body['latitude'] = latitude;
    if (longitude != null) body['longitude'] = longitude;
    final data = await api.post('/listings', body: body);
    return Listing.fromJson(data as Map<String, dynamic>);
  }

  Future<Listing> uploadPhoto(String listingId, {required Uint8List bytes, required String filename}) async {
    final data = await api.postMultipart(
      '/listings/$listingId/photos',
      fileField: 'file',
      fileBytes: bytes,
      filename: filename,
    );
    return Listing.fromJson(data as Map<String, dynamic>);
  }

  // ---- Owner dashboard ----

  /// Buy requests still awaiting review, newest first (GET /listings/dashboard/buy-requests).
  Future<List<BuyRequest>> dashboardBuyRequests() async {
    final data = await api.get('/listings/dashboard/buy-requests') as List<dynamic>;
    return data.map((json) => BuyRequest.fromJson(json as Map<String, dynamic>)).toList();
  }

  /// Approving marks the listing sold to this buyer; rejecting just declines the request.
  Future<BuyRequest> reviewBuyRequest(String requestId, {required bool approve}) async {
    final data = await api.post('/listings/buy-requests/$requestId/review', body: {'approve': approve});
    return BuyRequest.fromJson(data as Map<String, dynamic>);
  }
}
