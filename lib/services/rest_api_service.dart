import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:school_management_frontend/models/api_response.dart';
import 'package:school_management_frontend/services/session_storage_service.dart';

class RestApiService {
  static late RestApiService _service;

  static Future<RestApiService> getInstance() async {
    _service ??= RestApiService();
    return _service;
  }

  Future<ApiResponse<T>> apiGetSecured<T>(
      Uri uri, T Function(Map<String, dynamic>) fromJson) async {
    final headers = await createAuthHeader();
    if (headers == null) return ApiResponse<T>(body: null, code: 401);
    final response = await http.get(uri, headers: headers);
    return parseResponse(response, fromJson);
  }

  Future<ApiResponse<T>> apiGetNotSecured<T>(
      Uri uri, T Function(Map<String, dynamic>) fromJson) async {
    final response = await http.get(uri);
    return parseResponse(response, fromJson);
  }

  ApiResponse<T> parseResponse<T>(
      http.Response response, T Function(Map<String, dynamic>) fromJson) {
    if (response.statusCode == 200) {
      final parsedBody = fromJson(jsonDecode(response.body));
      return ApiResponse<T>(body: parsedBody, code: response.statusCode);
    } else {
      debugPrint("Request failed: ${response.statusCode}");
      return ApiResponse<T>(body: null, code: response.statusCode);
    }
  }

  Future<Map<String, String>?> createAuthHeader() async {
    var session = await SessionStorageService.getInstance();
    var token = session.retrieveAccessToken();
    if (token == null) return null;
    return {"Authorization": "Bearer $token"};
  }
}
