import 'dart:convert';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
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

  static String get baseUrl {
    if (kIsWeb) return 'http://localhost:8000';
    try {
      if (Platform.isAndroid) return 'http://10.0.2.2:8000';
    } catch (_) {
      // Platform is unavailable on some targets (e.g. web); already handled above.
    }
    return 'http://localhost:8000';
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
