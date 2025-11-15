// import 'dart:convert';
// import 'package:http/http.dart' as http;
// import 'api_service.dart';

// class AttendanceService extends ApiService {
//   AttendanceService({required super.baseUrl});

//   Future<List<dynamic>> getAllAttendance({int page = 0, int size = 10}) async {
//     final response = await http.get(
//       Uri.parse('$baseUrl/api/v1/attendance?page=$page&size=$size'),
//       headers: await getHeaders(authRequired: true),
//     );
//     if (response.statusCode == 200) {
//       final data = jsonDecode(response.body);
//       return data['content'] ?? [];
//     }
//     throw Exception('Failed to load attendance records');
//   }

//   Future<Map<String, dynamic>> markAttendance(Map<String, dynamic> data) async {
//     final response = await http.post(
//       Uri.parse('$baseUrl/api/v1/attendance'),
//       headers: await getHeaders(authRequired: true),
//       body: jsonEncode(data),
//     );
//     if (response.statusCode == 201) return jsonDecode(response.body);
//     throw Exception('Failed to mark attendance');
//   }

//   Future<void> deleteAttendance(int id) async {
//     final response = await http.delete(
//       Uri.parse('$baseUrl/api/v1/attendance/$id'),
//       headers: await getHeaders(authRequired: true),
//     );
//     if (response.statusCode != 200 && response.statusCode != 204) {
//       throw Exception('Failed to delete attendance');
//     }
//   }
// }
