import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/user.dart';
import '../services/api_client.dart';

/// Holds the logged-in user + JWT for the whole app, persisted across restarts.
/// There's no GET /auth/me on the backend, so the user profile returned at
/// login/signup time is cached alongside the token rather than re-fetched.
class AuthSession extends ChangeNotifier {
  AuthSession() : api = ApiClient();

  final ApiClient api;

  AppUser? _user;
  bool _bootstrapped = false;

  AppUser? get user => _user;
  bool get isLoggedIn => _user != null;
  bool get bootstrapped => _bootstrapped;

  static const _tokenKey = 'auth_token';
  static const _userKey = 'auth_user';

  Future<void> bootstrap() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_tokenKey);
    final userJson = prefs.getString(_userKey);
    if (token != null && userJson != null) {
      api.token = token;
      _user = AppUser.fromJson(jsonDecode(userJson) as Map<String, dynamic>);
    }
    _bootstrapped = true;
    notifyListeners();
  }

  Future<void> login(String email, String password) async {
    final response = await api.postForm('/auth/login', {
      'username': email,
      'password': password,
    });
    await _applyToken(response as Map<String, dynamic>);
  }

  Future<void> signup({required String name, required String phone, required String email, required String password}) async {
    final response = await api.post('/auth/signup', body: {
      'name': name,
      'phone': phone,
      'email': email,
      'password': password,
    });
    await _applyToken(response as Map<String, dynamic>);
  }

  Future<void> requestPasswordReset(String email) async {
    await api.post('/auth/forgot-password', body: {'email': email});
  }

  Future<void> resetPassword({required String email, required String code, required String newPassword}) async {
    final response = await api.post('/auth/reset-password', body: {
      'email': email,
      'code': code,
      'new_password': newPassword,
    });
    await _applyToken(response as Map<String, dynamic>);
  }

  Future<void> _applyToken(Map<String, dynamic> tokenResponse) async {
    final accessToken = tokenResponse['access_token'] as String;
    final user = AppUser.fromJson(tokenResponse['user'] as Map<String, dynamic>);

    api.token = accessToken;
    _user = user;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, accessToken);
    await prefs.setString(_userKey, jsonEncode(user.toJson()));

    notifyListeners();
  }

  Future<void> logout() async {
    api.token = null;
    _user = null;

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_userKey);
    // The Land Advisor chat is tied to whoever was logged in — don't leak it to the next user.
    await prefs.remove('advisor_conversation_id');
    await prefs.remove('advisor_messages');

    notifyListeners();
  }
}
