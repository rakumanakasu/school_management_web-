import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class SessionStorageService {
  static SessionStorageService? _instance;
  static SharedPreferences? _prefs;

  SessionStorageService._();

  static Future<SessionStorageService> getInstance() async {
    if (_instance == null) {
      _instance = SessionStorageService._();
      _prefs = await SharedPreferences.getInstance();
    }
    return _instance!;
  }

  /// ------------------ Tokens ------------------
  Future<void> saveAccessToken(String token) async {
    await _prefs?.setString('access_token', token);
  }

  Future<void> saveRefreshToken(String token) async {
    await _prefs?.setString('refresh_token', token);
  }

  String? retrieveAccessToken() => _prefs?.getString('access_token');
  String? retrieveRefreshToken() => _prefs?.getString('refresh_token');

  Future<void> clearToken() async {
    await _prefs?.remove('access_token');
    await _prefs?.remove('refresh_token');
  }

  /// ------------------ User Info ------------------
  Future<void> saveUser(Map<String, dynamic> user) async {
    await _prefs?.setString('user', jsonEncode(user));
  }

  Map<String, dynamic>? retrieveUser() {
    final userString = _prefs?.getString('user');
    if (userString == null) return null;
    return jsonDecode(userString) as Map<String, dynamic>;
  }

  Future<void> clearUser() async {
    await _prefs?.remove('user');
  }

  /// ------------------ Clear All ------------------
  Future<void> clearSession() async {
    await _prefs?.clear();
  }
}
