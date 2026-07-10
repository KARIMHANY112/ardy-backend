import 'listing.dart';

class Favorite {
  final String id;
  final Listing listing;
  final DateTime savedAt;

  Favorite({required this.id, required this.listing, required this.savedAt});

  factory Favorite.fromJson(Map<String, dynamic> json) => Favorite(
        id: json['id'] as String,
        listing: Listing.fromJson(json['listing'] as Map<String, dynamic>),
        savedAt: DateTime.parse(json['saved_at'] as String),
      );
}
