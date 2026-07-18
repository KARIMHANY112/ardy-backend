import 'dart:convert';

import 'package:http/http.dart' as http;

class ApiException implements Exception {
  final String message;
  final int? statusCode;
  ApiException(this.message, {this.statusCode});

  @override
  String toString() => message;
}

class ApiClient {
  ApiClient({this.token});

  String? token;

  // Override at build/run time with --dart-define=ARDY_API_BASE_URL=http://host:port
  static const String _baseUrlOverride =
      String.fromEnvironment('ARDY_API_BASE_URL');

  static const String _productionUrl = 'https://ardy-backend.onrender.com';

  static String get baseUrl {
    if (_baseUrlOverride.isNotEmpty) return _baseUrlOverride;
    return _productionUrl;
  }

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      };

  Uri _uri(String path) => Uri.parse('$baseUrl$path');

  Future<dynamic> get(String path) async {
    final res = await http.get(_uri(path), headers: _headers);
    return _handle(res);
  }

  Future<dynamic> post(String path, {Object? body}) async {
    final res = await http.post(_uri(path), headers: _headers, body: body == null ? null : jsonEncode(body));
    return _handle(res);
  }

  /// x-www-form-urlencoded POST — needed for endpoints built on FastAPI's
  /// OAuth2PasswordRequestForm (e.g. /auth/login), which won't accept JSON.
  Future<dynamic> postForm(String path, Map<String, String> fields) async {
    final res = await http.post(
      _uri(path),
      headers: {
        'Content-Type': 'application/x-www-form-urlencoded',
        if (token != null) 'Authorization': 'Bearer $token',
      },
      body: fields,
    );
    return _handle(res);
  }

  /// multipart/form-data POST for file uploads (e.g. listing photos).
  Future<dynamic> postMultipart(String path, {required String fileField, required List<int> fileBytes, required String filename}) async {
    final request = http.MultipartRequest('POST', _uri(path));
    if (token != null) request.headers['Authorization'] = 'Bearer $token';
    request.files.add(http.MultipartFile.fromBytes(fileField, fileBytes, filename: filename));
    final streamed = await request.send();
    final res = await http.Response.fromStream(streamed);
    return _handle(res);
  }

  Future<dynamic> delete(String path) async {
    final res = await http.delete(_uri(path), headers: _headers);
    return _handle(res);
  }

  dynamic _handle(http.Response res) {
    if (res.statusCode >= 200 && res.statusCode < 300) {
      if (res.body.isEmpty) return null;
      return jsonDecode(res.body);
    }
    String message = 'Request failed (${res.statusCode})';
    try {
      final decoded = jsonDecode(res.body);
      if (decoded is Map && decoded['detail'] != null) {
        message = decoded['detail'].toString();
      }
    } catch (_) {
      // Response body wasn't JSON — fall back to the generic message above.
    }
    throw ApiException(message, statusCode: res.statusCode);
  }
}
