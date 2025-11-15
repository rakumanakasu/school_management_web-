// import 'dart:convert';
// import 'package:http/http.dart' as http;
// import '../api_service.dart'; // make sure this path matches your folder

// class TeachersService {
//   final ApiService apiService;

//   TeachersService({required this.apiService});

//   // ✅ Private helper to build headers (no more _getHeaders error)
//   Future<Map<String, String>> _getHeaders() async {
//     return {
//       'Content-Type': 'application/json',
//       'Authorization': 'Bearer ${await apiService.getToken()}',
//     };
//   }

//   // ✅ Fetch all teachers
//   Future<List<dynamic>> fetchTeachers() async {
//     final url = Uri.parse('${apiService.baseUrl}/teachers');
//     final headers = await _getHeaders();

//     final response = await http.get(url, headers: headers);
//     if (response.statusCode == 200) {
//       return json.decode(response.body);
//     } else {
//       throw Exception('Failed to load teachers');
//     }
//   }

//   // ✅ Get teacher by ID
//   Future<Map<String, dynamic>> getTeacherById(int id) async {
//     final url = Uri.parse('${apiService.baseUrl}/teachers/$id');
//     final headers = await _getHeaders();

//     final response = await http.get(url, headers: headers);
//     if (response.statusCode == 200) {
//       return json.decode(response.body);
//     } else {
//       throw Exception('Teacher not found');
//     }
//   }

//   // ✅ Create a new teacher
//   Future<bool> createTeacher(Map<String, dynamic> teacherData) async {
//     final url = Uri.parse('${apiService.baseUrl}/teachers');
//     final headers = await _getHeaders();

//     final response = await http.post(
//       url,
//       headers: headers,
//       body: json.encode(teacherData),
//     );

//     return response.statusCode == 201;
//   }

//   // ✅ Update teacher
//   Future<bool> updateTeacher(int id, Map<String, dynamic> teacherData) async {
//     final url = Uri.parse('${apiService.baseUrl}/teachers/$id');
//     final headers = await _getHeaders();

//     final response = await http.put(
//       url,
//       headers: headers,
//       body: json.encode(teacherData),
//     );

//     return response.statusCode == 200;
//   }

//   // ✅ Delete teacher
//   Future<bool> deleteTeacher(int id) async {
//     final url = Uri.parse('${apiService.baseUrl}/teachers/$id');
//     final headers = await _getHeaders();

//     final response = await http.delete(url, headers: headers);
//     return response.statusCode == 204;
//   }
// }
