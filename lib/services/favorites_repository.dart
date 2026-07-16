import '../models/favorite.dart';
import 'api_client.dart';

class FavoritesRepository {
  FavoritesRepository(this.api);

  final ApiClient api;

  Future<List<Favorite>> list() async {
    final data = await api.get('/favorites') as List<dynamic>;
    return data.map((json) => Favorite.fromJson(json as Map<String, dynamic>)).toList();
  }

  Future<void> add(String listingId) => api.post('/favorites/$listingId');

  Future<void> remove(String listingId) => api.delete('/favorites/$listingId');
}
