// import 'dart:convert';
// import 'dart:io';
// import 'dart:typed_data';
// import 'package:flutter/foundation.dart';
// import 'package:http/http.dart' as http;
// import 'package:image_picker/image_picker.dart';
// import 'package:intl/intl.dart';
// import 'package:school_management_frontend/services/api/api_service.dart';


// class StudentsService extends ApiService {
//   StudentsService({required super.baseUrl});

//   Future<Map<String, dynamic>> createStudentMultipart(
//     Map<String, dynamic> data,
//     File? file, {
//     XFile? pickedFile,
//     Uint8List? webBytes,
//   }) async {
//     final uri = Uri.parse('$baseUrl/api/v1/students');
//     final request = http.MultipartRequest('POST', uri);
//     final headers = await getHeaders(authRequired: true);
//     request.headers.addAll(headers);

//     // Convert DateTime → yyyy-MM-dd
//     final formattedData = data.map((key, value) {
//       if (value is DateTime) {
//         return MapEntry(key, DateFormat('yyyy-MM-dd').format(value));
//       }
//       return MapEntry(key, value.toString());
//     });
//     formattedData.forEach((k, v) => request.fields[k] = v);

//     if (!kIsWeb && file != null) {
//       request.files.add(await http.MultipartFile.fromPath('file', file.path));
//     } else if (kIsWeb && webBytes != null && pickedFile != null) {
//       request.files.add(http.MultipartFile.fromBytes('file', webBytes, filename: pickedFile.name));
//     }

//     final response = await request.send();
//     final respStr = await response.stream.bytesToString();
//     if (response.statusCode == 201) return jsonDecode(respStr);
//     throw Exception('Failed to create student: $respStr');
//   }

//   Future<Map<String, dynamic>> updateStudentMultipart(
//     int id,
//     Map<String, dynamic> data,
//     File? file, {
//     XFile? pickedFile,
//     Uint8List? webBytes,
//   }) async {
//     final uri = Uri.parse('$baseUrl/api/v1/students/update/$id');
//     final request = http.MultipartRequest('POST', uri);
//     final headers = await getHeaders(authRequired: true);
//     request.headers.addAll(headers);

//     final formattedData = data.map((key, value) {
//       if (value is DateTime) {
//         return MapEntry(key, DateFormat('yyyy-MM-dd').format(value));
//       }
//       return MapEntry(key, value.toString());
//     });
//     formattedData.forEach((k, v) => request.fields[k] = v);

//     if (!kIsWeb && file != null) {
//       request.files.add(await http.MultipartFile.fromPath('file', file.path));
//     } else if (kIsWeb && webBytes != null && pickedFile != null) {
//       request.files.add(http.MultipartFile.fromBytes('file', webBytes, filename: pickedFile.name));
//     }

//     final response = await request.send();
//     final respStr = await response.stream.bytesToString();
//     if (response.statusCode == 200) return jsonDecode(respStr);
//     throw Exception('Failed to update student: $respStr');
//   }

//   Future<Map<String, dynamic>> getStudentById(int id) async {
//     final response = await http.get(
//       Uri.parse('$baseUrl/api/v1/students/$id'),
//       headers: await getHeaders(authRequired: true),
//     );
//     if (response.statusCode == 200) return jsonDecode(response.body);
//     throw Exception('Failed to fetch student');
//   }

//   Future<List<dynamic>> getAllStudents({int page = 0, int size = 10}) async {
//     final response = await http.get(
//       Uri.parse('$baseUrl/api/v1/students?page=$page&size=$size'),
//       headers: await getHeaders(authRequired: true),
//     );
//     if (response.statusCode == 200) {
//       return jsonDecode(response.body)['content'] ?? [];
//     }
//     throw Exception('Failed to fetch students');
//   }

//   Future<void> deleteStudent(int id) async {
//     final response = await http.delete(
//       Uri.parse('$baseUrl/api/v1/students/$id'),
//       headers: await getHeaders(authRequired: true),
//     );
//     if (response.statusCode != 200) throw Exception('Failed to delete student');
//   }
// }
