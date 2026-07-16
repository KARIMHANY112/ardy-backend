import '../models/listing.dart';
import 'api_client.dart';

class AdvisorResponse {
  final String reply;
  final List<Listing> matches;
  final String conversationId;
  final Map<String, dynamic> preferences;

  AdvisorResponse({required this.reply, required this.matches, required this.conversationId, required this.preferences});

  factory AdvisorResponse.fromJson(Map<String, dynamic> json) => AdvisorResponse(
        reply: json['reply'] as String,
        matches: (json['matches'] as List<dynamic>).map((m) => Listing.fromJson(m as Map<String, dynamic>)).toList(),
        conversationId: json['conversation_id'] as String,
        preferences: (json['preferences'] as Map<String, dynamic>?) ?? const {},
      );
}

class AdvisorRepository {
  AdvisorRepository(this.api);

  final ApiClient api;

  Future<AdvisorResponse> ask(String message, {String? conversationId}) async {
    final body = <String, dynamic>{'message': message};
    if (conversationId != null) body['conversation_id'] = conversationId;
    final data = await api.post('/advisor/ask', body: body);
    return AdvisorResponse.fromJson(data as Map<String, dynamic>);
  }
}
