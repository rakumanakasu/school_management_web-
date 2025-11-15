// import 'dart:convert';
// import 'package:http/http.dart' as http;
// import 'api_service.dart';

// class SubjectsService extends ApiService {
//   SubjectsService({required super.baseUrl});

//   Future<List<dynamic>> getAllSubjects({int page = 0, int size = 10}) async {
//     final response = await http.get(
//       Uri.parse('$baseUrl/api/v1/subjects?page=$page&size=$size'),
//       headers: await getHeaders(authRequired: true),
//     );

//     if (response.statusCode == 200) {
//       final data = jsonDecode(response.body);
//       return data['content'] ?? [];
//     }
//     throw Exception('Failed to load subjects');
//   }

//   Future<Map<String, dynamic>> createSubject(Map<String, dynamic> data) async {
//     final response = await http.post(
//       Uri.parse('$baseUrl/api/v1/subjects'),
//       headers: await getHeaders(authRequired: true),
//       body: jsonEncode(data),
//     );
//     if (response.statusCode == 201) return jsonDecode(response.body);
//     throw Exception('Failed to create subject');
//   }

//   Future<void> deleteSubject(int id) async {
//     final response = await http.delete(
//       Uri.parse('$baseUrl/api/v1/subjects/$id'),
//       headers: await getHeaders(authRequired: true),
//     );
//     if (response.statusCode != 200 && response.statusCode != 204) {
//       throw Exception('Failed to delete subject');
//     }
//   }
// }
