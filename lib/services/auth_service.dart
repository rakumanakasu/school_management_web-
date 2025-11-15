import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:school_management_frontend/config/config.dart';
import 'session_storage_service.dart';


class AuthService {
  static AuthService? _instance;
  final SessionStorageService _storage;

  AuthService._(this._storage);

  static Future<AuthService> getInstance() async {
    final storage = await SessionStorageService.getInstance();
    _instance ??= AuthService._(storage);
    return _instance!;
  }

  Future<http.Response> login(String username, String password) async {
    final url = Uri.parse(
        '${AppConfig.keycloakUrl}/realms/${AppConfig.keycloakRealm}/protocol/openid-connect/token');

    final response = await http.post(url, body: {
      'grant_type': 'password',
      'client_id': AppConfig.keycloakClientId,
      'username': username,
      'password': password,
      'client_secret': AppConfig.keycloakClientSecret
    });

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final accessToken = data['access_token'];
      await _storage.saveAccessToken(accessToken);
    }

    return response;
  }

  Future<List<String>> getUserRoles() async {
    final token = _storage.retrieveAccessToken();
    if (token == null) return [];

    final parts = token.split('.');
    if (parts.length != 3) return [];

    final payload = utf8.decode(base64Url.decode(base64Url.normalize(parts[1])));
    final Map<String, dynamic> jsonPayload = json.decode(payload);

    if (jsonPayload['realm_access'] == null) return [];
    final roles = (jsonPayload['realm_access']['roles'] as List<dynamic>)
        .map((e) => e.toString().toUpperCase())
        .toList();
    return roles;
  }

  Future<void> logout() async {
    await _storage.clearToken();
  }

  String? get token => _storage.retrieveAccessToken();
}
