// import 'dart:convert';
// import 'package:http/http.dart' as http;
// import 'api_service.dart';

// class UsersService extends ApiService {
//   UsersService({required super.baseUrl});

//   Future<List<dynamic>> getAllUsers({int page = 0, int size = 10}) async {
//     final response = await http.get(
//       Uri.parse('$baseUrl/api/v1/users?page=$page&size=$size'),
//       headers: await getHeaders(authRequired: true),
//     );
//     if (response.statusCode == 200) {
//       final data = jsonDecode(response.body);
//       return data['content'] ?? [];
//     }
//     throw Exception('Failed to load users');
//   }

//   Future<Map<String, dynamic>> getUserById(int id) async {
//     final response = await http.get(
//       Uri.parse('$baseUrl/api/v1/users/$id'),
//       headers: await getHeaders(authRequired: true),
//     );
//     if (response.statusCode == 200) return jsonDecode(response.body);
//     throw Exception('Failed to load user');
//   }

//   Future<Map<String, dynamic>> updateUser(int id, Map<String, dynamic> data) async {
//     final response = await http.put(
//       Uri.parse('$baseUrl/api/v1/users/$id'),
//       headers: await getHeaders(authRequired: true),
//       body: jsonEncode(data),
//     );
//     if (response.statusCode == 200) return jsonDecode(response.body);
//     throw Exception('Failed to update user');
//   }

//   Future<void> deleteUser(int id) async {
//     final response = await http.delete(
//       Uri.parse('$baseUrl/api/v1/users/$id'),
//       headers: await getHeaders(authRequired: true),
//     );
//     if (response.statusCode != 200 && response.statusCode != 204) {
//       throw Exception('Failed to delete user');
//     }
//   }
// }
