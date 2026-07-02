import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_core/shared_core.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Persists the auth token + user to local storage (localStorage on web).
class AuthStorage {
  static const _tokenKey = 'auth_token';
  static const _userKey = 'auth_user';

  Future<void> save(String token, User user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
    await prefs.setString(_userKey, jsonEncode(user.toJson()));
  }

  Future<({String token, User user})?> read() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_tokenKey);
    final userJson = prefs.getString(_userKey);
    if (token == null || userJson == null) return null;
    final user = User.fromJson(jsonDecode(userJson) as Map<String, dynamic>);
    return (token: token, user: user);
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_userKey);
  }
}

final authStorageProvider = Provider<AuthStorage>((ref) => AuthStorage());
