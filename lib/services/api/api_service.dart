// // services/api/api_service.dart
// import 'dart:convert';
// import 'package:http/http.dart' as http;
// import 'package:school_management_frontend/services/session_storage_service.dart';

// class ApiService {
//   final String baseUrl;

//   ApiService({required this.baseUrl});

//   /// ------------------ Helper ------------------
//   /// Get headers with Authorization if token exists
//   Future<Map<String, String>> getHeaders({bool authRequired = false}) async {
//     final headers = {'Content-Type': 'application/json'};

//     if (authRequired) {
//       final session = await SessionStorageService.getInstance();
//       final token = session.retrieveAccessToken();
//       if (token == null) {
//         throw Exception('No access token found. Please login first.');
//       }
//       headers['Authorization'] = 'Bearer $token';
//     }

//     return headers;
//   }

//   /// ------------------ Auth ------------------
//   Future<Map<String, dynamic>> registerUser(Map<String, dynamic> data) async {
//     final response = await http.post(
//       Uri.parse('$baseUrl/api/auth/register'),
//       headers: await getHeaders(),
//       body: jsonEncode(data),
//     );

//     if (response.statusCode == 201) {
//       return jsonDecode(response.body);
//     } else {
//       throw Exception(jsonDecode(response.body)['error'] ?? 'Registration failed');
//     }
//   }

//   Future<String> forgotPassword(String username) async {
//     final response = await http.post(
//       Uri.parse('$baseUrl/api/auth/forgot-password?username=$username'),
//       headers: await getHeaders(),
//     );

//     if (response.statusCode == 200) {
//       return response.body;
//     } else {
//       throw Exception('Failed to send reset password email');
//     }
//   }
// }
