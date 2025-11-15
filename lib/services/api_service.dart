import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'session_storage_service.dart';
import 'package:intl/intl.dart'; 

class ApiService {
  final String baseUrl;

  ApiService({required this.baseUrl});

  /// ------------------ Helper ------------------
  /// Get headers with Authorization if token exists
  Future<Map<String, String>> _getHeaders({bool authRequired = false}) async {
    final headers = {'Content-Type': 'application/json'};

    if (authRequired) {
      final session = await SessionStorageService.getInstance();
      final token = session.retrieveAccessToken();
      if (token == null) {
        throw Exception('No access token found. Please login first.');
      }
      headers['Authorization'] = 'Bearer $token';
    }

    return headers;
  }

  /// ------------------ Auth ------------------
  Future<Map<String, dynamic>> registerUser(Map<String, dynamic> data) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/auth/register'),
      headers: await _getHeaders(),
      body: jsonEncode(data),
    );

    if (response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      throw Exception(jsonDecode(response.body)['error'] ?? 'Registration failed');
    }
  }

  Future<String> forgotPassword(String username) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/auth/forgot-password?username=$username'),
      headers: await _getHeaders(),
    );

    if (response.statusCode == 200) {
      return response.body;
    } else {
      throw Exception('Failed to send reset password email');
    }
  }

Future<int> getCurrentStudentId() async {
  final session = await SessionStorageService.getInstance();
  final token = session.retrieveAccessToken();

  if (token == null) {
    throw Exception('No access token found. Please login first.');
  }

  // Decode JWT to get user info
  final decodedToken = JwtDecoder.decode(token);
  // Common claims: 'sub', 'email', 'username'
  final email = decodedToken['sub'] ?? decodedToken['email'];
  if (email == null) {
    throw Exception('Email not found in JWT');
  }

  // Fetch student info using email
  final student = await getStudentByEmail(email);
  return student['id'];
}

 /// ------------------ Students ------------------
// Fetch all students without pagination (for dropdowns)
Future<List<Map<String, dynamic>>> getStudents() async {
  final allStudentsResponse = await getAllStudents(page: 0, size: 1000); // fetch all
  final allStudents = allStudentsResponse['content'] as List<dynamic>;
  return allStudents.map((e) => Map<String, dynamic>.from(e)).toList();
}

/// Get student by email
Future<Map<String, dynamic>> getStudentByEmail(String email) async {
  final uri = Uri.parse('$baseUrl/api/v1/students/searchByEmail?email=$email');
  final response = await http.get(uri, headers: await _getHeaders(authRequired: true));

  if (response.statusCode == 200) {
    final data = jsonDecode(response.body);
    if (data is List && data.isNotEmpty) {
      return data[0]; // return the first matching student
    }
    throw Exception('Student not found with email: $email');
  } else {
    throw Exception('Failed to fetch student by email: ${response.body}');
  }
}

Future<Map<String, dynamic>> createStudentMultipart(
  Map<String, dynamic> data,
  File? file, {
  XFile? pickedFile,
  Uint8List? webBytes,
}) async {
  final uri = Uri.parse('$baseUrl/api/v1/students');
  final request = http.MultipartRequest('POST', uri);
  final headers = await _getHeaders(authRequired: true);
  request.headers.addAll(headers);

  // Convert DateTime fields to yyyy-MM-dd
  final formattedData = data.map((key, value) {
    if (value is DateTime) {
      return MapEntry(key, DateFormat('yyyy-MM-dd').format(value));
    }
    return MapEntry(key, value.toString());
  });

  formattedData.forEach((k, v) => request.fields[k] = v);

  if (!kIsWeb && file != null) {
    request.files.add(await http.MultipartFile.fromPath('file', file.path));
  } else if (kIsWeb && webBytes != null && pickedFile != null) {
    request.files.add(http.MultipartFile.fromBytes(
      'file',
      webBytes,
      filename: pickedFile.name,
    ));
  }

  final response = await request.send();
  final respStr = await response.stream.bytesToString();
  if (response.statusCode == 201) return jsonDecode(respStr);
  throw Exception('Failed to create student: $respStr');
}

Future<Map<String, dynamic>> updateStudentMultipart(
  int id,
  Map<String, dynamic> data,
  File? file, {
  XFile? pickedFile,
  Uint8List? webBytes,
}) async {
  final uri = Uri.parse('$baseUrl/api/v1/students/update/$id');
  final request = http.MultipartRequest('POST', uri);
  final headers = await _getHeaders(authRequired: true);
  request.headers.addAll(headers);

  // Convert DateTime fields to yyyy-MM-dd
  final formattedData = data.map((key, value) {
    if (value is DateTime) {
      return MapEntry(key, DateFormat('yyyy-MM-dd').format(value));
    }
    return MapEntry(key, value.toString());
  });

  formattedData.forEach((key, value) => request.fields[key] = value);

  if (!kIsWeb && file != null) {
    request.files.add(await http.MultipartFile.fromPath('file', file.path));
  }
  if (kIsWeb && webBytes != null && pickedFile != null) {
    request.files.add(http.MultipartFile.fromBytes(
      'file',
      webBytes,
      filename: pickedFile.name,
    ));
  }

  final response = await request.send();
  final respStr = await response.stream.bytesToString();
  if (response.statusCode == 200) return jsonDecode(respStr);
  throw Exception('Failed to update student: $respStr');
}

  Future<Map<String, dynamic>> getStudentById(int id) async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/v1/students/$id'),
      headers: await _getHeaders(authRequired: true),
    );
    if (response.statusCode == 200) return jsonDecode(response.body);
    throw Exception('Failed to fetch student');
  }

Future<Map<String, dynamic>> getAllStudents({
  int page = 0,
  int size = 10,
  String? searchQuery,
}) async {
  final queryParams = {
    'page': page.toString(),
    'size': size.toString(),
    if (searchQuery != null && searchQuery.isNotEmpty) 'search': searchQuery,
  };

  final uri = Uri.parse('$baseUrl/api/v1/students')
      .replace(queryParameters: queryParams);

  final response =
      await http.get(uri, headers: await _getHeaders(authRequired: true));

  if (response.statusCode == 200) {
    final data = jsonDecode(response.body);
    return {
      'content': data['content'] ?? [],
      'totalPages': data['totalPages'] ?? 1,
    };
  } else {
    throw Exception('Failed to fetch students: ${response.body}');
  }
}

/// Student Detail 
Future<Map<String, dynamic>> getStudentDetail(int id) async {
  final response = await http.get(
    Uri.parse('$baseUrl/api/v1/students/detail/$id'),
    headers: await _getHeaders(authRequired: true),
  );

  if (response.statusCode == 200) {
    return jsonDecode(response.body);
  } else {
    throw Exception('Failed to fetch student detail: ${response.body}');
  }
}

  Future<void> deleteStudent(int id) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/api/v1/students/$id'),
      headers: await _getHeaders(authRequired: true),
    );
    if (response.statusCode != 200) throw Exception('Failed to delete student');
  }

Future<List<Map<String, dynamic>>> getStudentsByClassId(int classId) async {
  final headers = await _getHeaders(authRequired: true);
  final response = await http.get(
    Uri.parse('$baseUrl/api/v1/students/by-class/$classId'), // <-- include api/v1
    headers: headers,
  );

  if (response.statusCode == 200) {
    return List<Map<String, dynamic>>.from(json.decode(response.body));
  } else {
    throw Exception('Failed to load students by class: ${response.body}');
  }
}


  /// ------------------ Teachers ------------------
  
  Future<List<Map<String, dynamic>>> getTeachers() async {
  final uri = Uri.parse('$baseUrl/api/v1/teachers?page=0&size=1000'); // fetch all
  final response = await http.get(uri, headers: await _getHeaders(authRequired: true));

  if (response.statusCode == 200) {
    final Map<String, dynamic> jsonData = jsonDecode(response.body);
    final List<dynamic> list = jsonData['content'] ?? [];
    return list.map((e) => Map<String, dynamic>.from(e)).toList();
  }
  throw Exception('Failed to fetch teachers: ${response.body}');
}
  Future<Map<String, dynamic>> createTeacher(Map<String, dynamic> data) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/v1/teachers'),
      headers: await _getHeaders(authRequired: true),
      body: jsonEncode(data),
    );
    if (response.statusCode == 201) return jsonDecode(response.body);
    throw Exception('Failed to create teacher');
  }

  Future<List<dynamic>> getAllTeachers({int page = 0, int size = 10}) async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/v1/teachers?page=$page&size=$size'),
      headers: await _getHeaders(authRequired: true),
    );
    if (response.statusCode == 200) return jsonDecode(response.body)['content'] ?? [];
    throw Exception('Failed to fetch teachers');
  }

  Future<Map<String, dynamic>> updateTeacher(int id, Map<String, dynamic> data) async {
    final response = await http.put(
      Uri.parse('$baseUrl/api/v1/teachers/$id'),
      headers: await _getHeaders(authRequired: true),
      body: jsonEncode(data),
    );
    if (response.statusCode == 200) return jsonDecode(response.body);
    throw Exception('Failed to update teacher');
  }

   Future<Map<String, dynamic>> createTeacherMultipart(
    Map<String, dynamic> data, {
    File? file,
    XFile? pickedFile,
    Uint8List? webBytes,
  }) async {
    final uri = Uri.parse('$baseUrl/api/v1/teachers');
    final request = http.MultipartRequest('POST', uri);
    final headers = await _getHeaders(authRequired: true);
    request.headers.addAll(headers);

    // Convert DateTime fields to yyyy-MM-dd if needed
    final formattedData = data.map((key, value) {
      if (value is DateTime) {
        return MapEntry(key, DateFormat('yyyy-MM-dd').format(value));
      }
      return MapEntry(key, value.toString());
    });

    formattedData.forEach((k, v) => request.fields[k] = v);

    // Add file
    if (!kIsWeb && file != null) {
      request.files.add(await http.MultipartFile.fromPath('file', file.path));
    } else if (kIsWeb && pickedFile != null && webBytes != null) {
      request.files.add(http.MultipartFile.fromBytes('file', webBytes, filename: pickedFile.name));
    }

    final response = await request.send();
    final respStr = await response.stream.bytesToString();
    if (response.statusCode == 201) return jsonDecode(respStr);
    throw Exception('Failed to create teacher: $respStr');
  }

   Future<Map<String, dynamic>> updateTeacherMultipart(
    int id,
    Map<String, dynamic> data, {
    File? file,
    XFile? pickedFile,
    Uint8List? webBytes,
  }) async {
    final uri = Uri.parse('$baseUrl/api/v1/teachers/$id');
    final request = http.MultipartRequest('PUT', uri);
    final headers = await _getHeaders(authRequired: true);
    request.headers.addAll(headers);

    // Convert DateTime fields to yyyy-MM-dd if needed
    final formattedData = data.map((key, value) {
      if (value is DateTime) {
        return MapEntry(key, DateFormat('yyyy-MM-dd').format(value));
      }
      return MapEntry(key, value.toString());
    });

    formattedData.forEach((k, v) => request.fields[k] = v);

    // Add file
    if (!kIsWeb && file != null) {
      request.files.add(await http.MultipartFile.fromPath('file', file.path));
    } else if (kIsWeb && pickedFile != null && webBytes != null) {
      request.files.add(http.MultipartFile.fromBytes('file', webBytes, filename: pickedFile.name));
    }

    final response = await request.send();
    final respStr = await response.stream.bytesToString();
    if (response.statusCode == 200) return jsonDecode(respStr);
    throw Exception('Failed to update teacher: $respStr');
  }


  Future<void> deleteTeacher(int id) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/api/v1/teachers/$id'),
      headers: await _getHeaders(authRequired: true),
    );
    if (response.statusCode != 200) throw Exception('Failed to delete teacher');
  }


/// ------------------ Grades ------------------
Future<Map<String, dynamic>> getAllGrades({int page = 0, int size = 10}) async {
  final uri = Uri.parse('$baseUrl/api/v1/grades?page=$page&size=$size');
  final response = await http.get(uri, headers: await _getHeaders(authRequired: true));

  if (response.statusCode == 200) {
    final data = jsonDecode(response.body);

   
    final content = (data['content'] as List<dynamic>?) ?? [];

    return {
      'content': content,
      'totalPages': data['totalPages'] ?? 1,
    };
  } else {
    throw Exception('Failed to fetch grades: ${response.body}');
  }
}

Future<void> createGrade(Map<String, dynamic> data) async {
  final response = await http.post(
    Uri.parse('$baseUrl/api/v1/grades'),
    headers: await _getHeaders(authRequired: true),
    body: jsonEncode(data),
  );
  if (response.statusCode != 201) {
    throw Exception('Failed to create grade: ${response.body}');
  }
}

Future<void> updateGrade(int id, Map<String, dynamic> data) async {
  final response = await http.put(
    Uri.parse('$baseUrl/api/v1/grades/$id'),
    headers: await _getHeaders(authRequired: true),
    body: jsonEncode(data),
  );
  if (response.statusCode != 200) {
    throw Exception('Failed to update grade: ${response.body}');
  }
}

Future<void> deleteGrade(int id) async {
  final response = await http.delete(
    Uri.parse('$baseUrl/api/v1/grades/$id'),
    headers: await _getHeaders(authRequired: true),
  );
  if (response.statusCode != 200) {
    throw Exception('Failed to delete grade: ${response.body}');
  }
}

Future<List<Map<String, dynamic>>> getGradesByStudent(int studentId) async {
  final response = await http.get(
    Uri.parse('$baseUrl/api/v1/grades/student/$studentId'),
    headers: await _getHeaders(authRequired: true),
  );
  if (response.statusCode == 200) {
    final List<dynamic> list = jsonDecode(response.body);
    return list.map((e) => Map<String, dynamic>.from(e)).toList().cast<Map<String, dynamic>>();
  } else {
    throw Exception('Failed to load grades by student: ${response.body}');
  }
}

Future<List<Map<String, dynamic>>> getGradesByStudentAndSubject(int studentId, int subjectId) async {
  final response = await http.get(
    Uri.parse('$baseUrl/api/v1/grades/student/$studentId/subject/$subjectId'),
    headers: await _getHeaders(authRequired: true),
  );
  if (response.statusCode == 200) {
    final List<dynamic> list = jsonDecode(response.body);
    return list.map((e) => Map<String, dynamic>.from(e)).toList().cast<Map<String, dynamic>>();
  } else {
    throw Exception('Failed to load grades by student and subject: ${response.body}');
  }
}

  /// ------------------ Attendances ------------------
  // Fetch all attendances
  Future<List<dynamic>> getAllAttendances({int page = 0, int size = 1000}) async {
    final uri = Uri.parse('$baseUrl/api/v1/attendances?page=$page&size=$size');
    final response = await http.get(uri, headers: await _getHeaders(authRequired: true));

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw Exception('Failed to fetch attendances');
  }

  // Create new attendance
  Future<Map<String, dynamic>> createAttendance({
  required int studentId,
  required int subjectId,
  required bool present,
  required String date,
}) async {
  assert(studentId != 0, 'studentId cannot be null or zero');
  assert(subjectId != 0, 'subjectId cannot be null or zero');

  final uri = Uri.parse('$baseUrl/api/v1/attendances');
  final body = jsonEncode({
    "studentId": studentId,
    "subjectId": subjectId,
    "present": present,
    "date": date,
  });

  final response = await http.post(
    uri,
    headers: await _getHeaders(authRequired: true),
    body: body,
  );

  if (response.statusCode == 201 || response.statusCode == 200) {
    return jsonDecode(response.body);
  }
  throw Exception('Failed to create attendance: ${response.body}');
}

  // Update existing attendance by ID
  Future<Map<String, dynamic>> updateAttendance(int id, bool present) async {
  final uri = Uri.parse('$baseUrl/api/v1/attendances/$id');
  final body = jsonEncode({"present": present});

  final response = await http.put(
    uri,
    headers: await _getHeaders(authRequired: true),
    body: body,
  );

  if (response.statusCode == 200) {
    final Map<String, dynamic> res = jsonDecode(response.body);

    
    return res['data'] as Map<String, dynamic>;
  }

  throw Exception('Failed to update attendance: ${response.body}');
}

  // Delete attendance
  Future<void> deleteAttendance(int id) async {
    final uri = Uri.parse('$baseUrl/api/v1/attendances/$id');
    final response = await http.delete(uri, headers: await _getHeaders(authRequired: true));

    if (response.statusCode != 200) {
      throw Exception('Failed to delete attendance: ${response.body}');
    }
  }

  // Fetch attendances by student ID
  Future<Map<String, dynamic>> getAttendanceByStudent(int studentId) async {
    final uri = Uri.parse('$baseUrl/api/v1/attendances/student/$studentId');
    final response = await http.get(uri, headers: await _getHeaders(authRequired: true));

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw Exception('Failed to fetch student attendance');
  }

  // Fetch attendances by date
  Future<List<dynamic>> getAttendanceByDate(String date) async {
    final uri = Uri.parse('$baseUrl/api/v1/attendances/date/$date');
    final response = await http.get(uri, headers: await _getHeaders(authRequired: true));

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw Exception('Failed to fetch attendance by date');
  }

Future<List<Map<String, dynamic>>> getSubjectsByClass(String className) async {
  try {
    final headers = await _getHeaders(authRequired: true); // add auth header
    final response = await http.get(
      Uri.parse('$baseUrl/api/v1/subject/by-class/$className'),
      headers: headers,
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.cast<Map<String, dynamic>>();
    } else {
      throw Exception('Failed to fetch subjects: ${response.statusCode}');
    }
  } catch (e) {
    print('Error fetching subjects for class $className: $e');
    return [];
  }
}

// Fetch attendances by class name
Future<List<Map<String, dynamic>>> getAttendancesByClassId(int classId) async {
  final uri = Uri.parse('$baseUrl/api/v1/attendances/class/$classId');
  final response = await http.get(uri, headers: await _getHeaders(authRequired: true));

  if (response.statusCode == 200) {
    final List<dynamic> data = jsonDecode(response.body);
    return data.cast<Map<String, dynamic>>();
  }
  throw Exception('Failed to fetch attendances for class $classId: ${response.body}');
}

/// Fetch attendances by class with pagination and optional search
Future<Map<String, dynamic>> getAttendancesByClassIdPaged({
  required int classId,
  int page = 0,
  int size = 5,
  String? search,
}) async {
  final queryParams = {
    'page': page.toString(),
    'size': size.toString(),
    if (search != null && search.isNotEmpty) 'search': search,
  };

  final uri = Uri.parse('$baseUrl/api/v1/attendances/class/$classId')
      .replace(queryParameters: queryParams);

  final response = await http.get(uri, headers: await _getHeaders(authRequired: true));

  if (response.statusCode == 200) {
    return jsonDecode(response.body);
  }
  throw Exception('Failed to fetch attendances for class $classId: ${response.body}');
}



/// ------------------ Dashboard Stats ------------------
Future<Map<String, dynamic>> getDashboardStats() async {
  try {
    final response = await http.get(
      Uri.parse('$baseUrl/api/v1/dashboard/stats'),
      headers: await _getHeaders(authRequired: true),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      // Safely extract values with defaults
      return {
        'students': data['students'] ?? 0,
        'teachers': data['teachers'] ?? 0,
        'grades': data['grades'] ?? 0,
        'attendance': data['attendance'] ?? 0,
        'absentCount': data['absentCount'] ?? 0, 
        'warning': data['warning'] ?? '',
        'role': data['role'] != null
            ? List<String>.from(data['role'])
            : <String>[],
      };
    } else {
      throw Exception('Failed to fetch dashboard stats: ${response.body}');
    }
  } catch (e) {
    debugPrint('Error fetching dashboard stats: $e');
    // fallback defaults
    return {
      'students': 0,
      'teachers': 0,
      'grades': 0,
      'attendance': 0,
      'absentCount': 0,
      'warning': '',
      'role': <String>[],
    };
  }
}

   // ----------------- Users -----------------
Future<List<dynamic>> getAllUsers() async {
  final headers = await _getHeaders(authRequired: true);
  final response = await http.get(
    Uri.parse('$baseUrl/api/v1/users'),
    headers: headers,
  );
  if (response.statusCode == 200) {
    return jsonDecode(response.body);
  } else {
    throw Exception('Failed to load users: ${response.body}');
  }
}

Future<void> createUser(Map<String, dynamic> data) async {
  final uri = Uri.parse('$baseUrl/api/v1/users');
  final headers = await _getHeaders(authRequired: true);

  // Use http.Request for exact control
  final request = http.Request('POST', uri)
    ..headers.addAll({
      'Content-Type': 'application/json', // exact, no charset
      if (headers.containsKey('Authorization'))
        'Authorization': headers['Authorization']!,
    })
    ..body = jsonEncode(data);

  final streamedResponse = await request.send();
  final responseStr = await streamedResponse.stream.bytesToString();

  if (streamedResponse.statusCode != 201) {
    throw Exception('Failed to create user: $responseStr');
  }
}


Future<void> updateUser(int id, Map<String, dynamic> data) async {
  final uri = Uri.parse('$baseUrl/api/v1/users/$id');
  final headers = await _getHeaders(authRequired: true);

  if (data['password'] == '') data.remove('password'); // don't overwrite empty password

  final request = http.Request('PUT', uri)
    ..headers.addAll({
      'Content-Type': 'application/json', // exact
      if (headers.containsKey('Authorization'))
        'Authorization': headers['Authorization']!,
    })
    ..body = jsonEncode(data);

  final streamedResponse = await request.send();
  final responseStr = await streamedResponse.stream.bytesToString();

  if (streamedResponse.statusCode != 200) {
    throw Exception('Failed to update user: $responseStr');
  }
}

Future<void> deleteUser(int id) async {
  final headers = await _getHeaders(authRequired: true);
  final response = await http.delete(
    Uri.parse('$baseUrl/api/v1/users/$id'),
    headers: headers,
  );
  if (response.statusCode != 200) {
    throw Exception('Failed to delete user: ${response.body}');
  }
}

Future<Map<String, dynamic>> getUserById(int id) async {
  final headers = await _getHeaders(authRequired: true);
  final response = await http.get(
    Uri.parse('$baseUrl/api/v1/users/$id'),
    headers: headers,
  );
  if (response.statusCode == 200) {
    return jsonDecode(response.body);
  } else {
    throw Exception('Failed to fetch user by id: ${response.body}');
  }
}

Future<List<dynamic>> searchUsersByUsername(String username) async {
  final headers = await _getHeaders(authRequired: true);

  // Call the backend search endpoint
  final uri = Uri.parse('$baseUrl/api/v1/users/search?username=$username');
  final response = await http.get(uri, headers: headers);

  if (response.statusCode == 200) {
    return jsonDecode(response.body);
  } else {
    throw Exception('Failed to search users: ${response.body}');
  }
}

Future<Map<String, dynamic>> getUsersPaged({
  int page = 0,
  int size = 10,
  String? username,
}) async {
  final headers = await _getHeaders(authRequired: true);

  var queryParameters = {
    'page': page.toString(),
    'size': size.toString(),
  };
  if (username != null && username.isNotEmpty) {
    queryParameters['username'] = username;
  }

  final uri = Uri.parse('$baseUrl/api/v1/users/paged').replace(queryParameters: queryParameters);
  final response = await http.get(uri, headers: headers);

  if (response.statusCode == 200) {
    return jsonDecode(response.body); // returns Page object: {"content":[...], "totalPages":..., "totalElements":...}
  } else {
    throw Exception('Failed to load users: ${response.body}');
  }
}



 /// ------------------ Classrooms ------------------
 Future<List<Map<String, dynamic>>> getClassrooms({int page = 0, int size = 100}) async {
  final response = await http.get(
    Uri.parse('$baseUrl/api/v1/classrooms?page=$page&size=$size'),
    headers: await _getHeaders(authRequired: true),
  );

  if (response.statusCode == 200) {
    final data = jsonDecode(response.body);
    final List<dynamic> content = data['content'] ?? [];

   
    return content.map((e) {
      final classroom = Map<String, dynamic>.from(e);
      if (classroom['teacher'] != null) {
        final teacher = Map<String, dynamic>.from(classroom['teacher']);
        classroom['teacher'] = {
          'id': teacher['id'],
          'firstName': teacher['firstName'],
          'lastName': teacher['lastName'],
        };
      }
      return classroom;
    }).toList();
  } else {
    throw Exception('Failed to fetch classrooms: ${response.body}');
  }
}


  Future<Map<String, dynamic>> createClassroom(Map<String, dynamic> data) async {
    final body = {
      'className': data['name'],
      'roomNumber': data['roomNumber'],
      if (data['teacherId'] != null) 'teacherId': data['teacherId'],
      if (data['studentIds'] != null) 'studentIds': data['studentIds'],
    };
    final response = await http.post(
      Uri.parse('$baseUrl/api/v1/classrooms'),
      headers: await _getHeaders(authRequired: true),
      body: jsonEncode(body),
    );
    if (response.statusCode == 201) return jsonDecode(response.body)['data'];
    throw Exception('Failed to create classroom: ${response.body}');
  }

  Future<Map<String, dynamic>> updateClassroom(int id, Map<String, dynamic> data) async {
    final body = {
      'className': data['name'],
      'roomNumber': data['roomNumber'],
      if (data['teacherId'] != null) 'teacherId': data['teacherId'],
      if (data['studentIds'] != null) 'studentIds': data['studentIds'],
    };
    final response = await http.put(
      Uri.parse('$baseUrl/api/v1/classrooms/$id'),
      headers: await _getHeaders(authRequired: true),
      body: jsonEncode(body),
    );
    if (response.statusCode == 200) return jsonDecode(response.body)['data'];
    throw Exception('Failed to update classroom: ${response.body}');
  }

  Future<void> deleteClassroom(int id) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/api/v1/classrooms/$id'),
      headers: await _getHeaders(authRequired: true),
    );
    if (response.statusCode != 200) throw Exception('Failed to delete classroom');
  }

 /// ------------------ Subjects ------------------
// Fetch all subjects without pagination (for dropdowns)
Future<List<Map<String, dynamic>>> getSubjects() async {
  final response = await getAllSubjects(page: 0, size: 1000); // fetch all
  final List<dynamic> list = response['content'] ?? [];
  return list.map((e) => Map<String, dynamic>.from(e)).toList();
}
 
Future<Map<String, dynamic>> getAllSubjects({int page = 0, int size = 10}) async {
  final response = await http.get(
    Uri.parse('$baseUrl/api/v1/subject?page=$page&size=$size'),
    headers: await _getHeaders(authRequired: true),
  );
  if (response.statusCode == 200) {
    return jsonDecode(response.body);
  }
  throw Exception('Failed to load subjects');
}

Future<Map<String, dynamic>> searchSubjects(String query, {int page = 0, int size = 10}) async {
  final response = await http.get(
    Uri.parse('$baseUrl/api/v1/subject/searchByName?name=$query&page=$page&size=$size'),
    headers: await _getHeaders(authRequired: true),
  );
  if (response.statusCode == 200) {
    return jsonDecode(response.body);
  }
  throw Exception('Failed to search subjects');
}

Future<void> createSubject(Map<String, dynamic> data) async {
  final response = await http.post(
    Uri.parse('$baseUrl/api/v1/subject'),
    headers: await _getHeaders(authRequired: true),
    body: jsonEncode(data),
  );

  if (response.statusCode != 201) {
    throw Exception('Failed to create subject: ${response.body}');
  }
}

Future<Map<String, dynamic>> getSubjectsPage(int page, int size, [String? name]) async {
  final uri = Uri.parse(
      name == null || name.isEmpty
          ? "$baseUrl/api/v1/subject?page=$page&size=$size"
          : "$baseUrl/api/v1/subject/searchByName?name=$name&page=$page&size=$size");

  final response = await http.get(uri);
  if (response.statusCode == 200) {
    return json.decode(response.body);
  } else {
    throw Exception('Failed to fetch subjects');
  }
}

Future<void> updateSubject(int id, Map<String, dynamic> data) async {
  final response = await http.put(
    Uri.parse('$baseUrl/api/v1/subject/$id'),
    headers: await _getHeaders(authRequired: true),
    body: jsonEncode(data),
  );

  if (response.statusCode != 200) {
    throw Exception('Failed to update subject: ${response.body}');
  }
}

Future<void> deleteSubject(int id) async {
  final response = await http.delete(
    Uri.parse('$baseUrl/api/v1/subject/$id'),
    headers: await _getHeaders(authRequired: true),
  );
  if (response.statusCode != 200) {
    throw Exception('Failed to delete subject: ${response.body}');
  }
}
Future<List<Map<String, dynamic>>> getSubjectsByClassId(int classId) async {
  final headers = await _getHeaders(authRequired: true);
  final response = await http.get(
    Uri.parse('$baseUrl/api/v1/subject/class/$classId'), 
    headers: headers,
  );

  if (response.statusCode == 200) {
    return List<Map<String, dynamic>>.from(json.decode(response.body));
  } else {
    throw Exception('Failed to load subjects by class: ${response.body}');
  }
}


}
