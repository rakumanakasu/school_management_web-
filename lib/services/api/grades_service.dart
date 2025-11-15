// import 'dart:convert';
// import 'package:http/http.dart' as http;
// import 'api_service.dart';

// class GradesService extends ApiService {
//   GradesService({required super.baseUrl});

//   /// Get all grades with pagination
//   Future<Map<String, dynamic>> getAllGrades({int page = 0, int size = 10}) async {
//     final response = await http.get(
//       Uri.parse('$baseUrl/api/v1/grades?page=$page&size=$size'),
//       headers: await getHeaders(authRequired: true),
//     );

//     if (response.statusCode == 200) {
//       return jsonDecode(response.body);
//     }
//     throw Exception('Failed to load grades');
//   }

//   /// Get grades by student
//   Future<List<dynamic>> getGradesByStudent(int studentId) async {
//     final response = await http.get(
//       Uri.parse('$baseUrl/api/v1/grades/student/$studentId'),
//       headers: await getHeaders(authRequired: true),
//     );

//     if (response.statusCode == 200) {
//       final data = jsonDecode(response.body);
//       return data['content'] ?? [];
//     }
//     throw Exception('Failed to load grades for student');
//   }

//   /// Get grades by student and subject
//   Future<List<dynamic>> getGradesByStudentAndSubject(int studentId, int subjectId) async {
//     final response = await http.get(
//       Uri.parse('$baseUrl/api/v1/grades/student/$studentId/subject/$subjectId'),
//       headers: await getHeaders(authRequired: true),
//     );

//     if (response.statusCode == 200) {
//       final data = jsonDecode(response.body);
//       return data['content'] ?? [];
//     }
//     throw Exception('Failed to load grades for student and subject');
//   }

//   /// Create a grade
//   Future<Map<String, dynamic>> createGrade(Map<String, dynamic> data) async {
//     final response = await http.post(
//       Uri.parse('$baseUrl/api/v1/grades'),
//       headers: await getHeaders(authRequired: true),
//       body: jsonEncode(data),
//     );
//     if (response.statusCode == 201) return jsonDecode(response.body);
//     throw Exception('Failed to create grade');
//   }

//   /// Update a grade
//   Future<Map<String, dynamic>> updateGrade(int id, Map<String, dynamic> data) async {
//     final response = await http.put(
//       Uri.parse('$baseUrl/api/v1/grades/$id'),
//       headers: await getHeaders(authRequired: true),
//       body: jsonEncode(data),
//     );
//     if (response.statusCode == 200) return jsonDecode(response.body);
//     throw Exception('Failed to update grade');
//   }

//   /// Delete a grade
//   Future<void> deleteGrade(int id) async {
//     final response = await http.delete(
//       Uri.parse('$baseUrl/api/v1/grades/$id'),
//       headers: await getHeaders(authRequired: true),
//     );
//     if (response.statusCode != 200 && response.statusCode != 204) {
//       throw Exception('Failed to delete grade');
//     }
//   }
// }
