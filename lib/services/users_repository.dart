import '../models/user.dart';
import 'api_client.dart';

class UsersRepository {
  UsersRepository(this.api);

  final ApiClient api;

  /// Buyers who signed up and are awaiting owner approval (GET /users/dashboard/pending).
  Future<List<AppUser>> pendingBuyers() async {
    final data = await api.get('/users/dashboard/pending') as List<dynamic>;
    return data.map((json) => AppUser.fromJson(json as Map<String, dynamic>)).toList();
  }

  Future<AppUser> review(String userId, {required bool approve}) async {
    final data = await api.post('/users/$userId/review', body: {'approve': approve});
    return AppUser.fromJson(data as Map<String, dynamic>);
  }
}
