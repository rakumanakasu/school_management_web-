import 'package:flutter/material.dart';
import '../services/api_service.dart';

class StudentDetailScreen extends StatefulWidget {
  final ApiService apiService;
  final Map<String, dynamic> student; // passed from students.dart

  const StudentDetailScreen({
    super.key,
    required this.apiService,
    required this.student,
  });

  @override
  State<StudentDetailScreen> createState() => _StudentDetailScreenState();
}

class _StudentDetailScreenState extends State<StudentDetailScreen> {
  late Map<String, dynamic> student;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    student = widget.student;
    fetchStudentDetail();
  }

  Future<void> fetchStudentDetail() async {
    setState(() => isLoading = true);
    try {
      final detail = await widget.apiService.getStudentDetail(student['id']);
      setState(() => student = detail);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to refresh student details: $e')),
      );
    }
    setState(() => isLoading = false);
  }

  Widget _buildInfoTile(String label, String? value) {
    return ListTile(
      title: Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text(value ?? '-'),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${student['firstName']} ${student['lastName']}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: fetchStudentDetail,
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  if (student['photo'] != null)
                    CircleAvatar(
                      radius: 60,
                      backgroundImage: NetworkImage(student['photo']),
                    )
                  else
                    const CircleAvatar(
                      radius: 60,
                      child: Icon(Icons.person, size: 50),
                    ),
                  const SizedBox(height: 20),
                  Card(
                    elevation: 3,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    child: Column(
                      children: [
                        _buildInfoTile('First Name', student['firstName']),
                        _buildInfoTile('Last Name', student['lastName']),
                        _buildInfoTile('Email', student['email']),
                        _buildInfoTile('Gender', student['gender']),
                        _buildInfoTile('Address', student['address']),
                        _buildInfoTile('Date of Birth', student['dob']),
                        _buildInfoTile(
                          'Classroom',
                          student['classroom'] != null
                              ? student['classroom']['className']
                              : '-',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  if (student['grades'] != null &&
                      student['grades'] is List &&
                      (student['grades'] as List).isNotEmpty)
                    Card(
                      elevation: 3,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                      child: Column(
                        children: [
                          const ListTile(
                            title: Text(
                              'Grades',
                              style: TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                          ),
                          ...List.generate(
                            (student['grades'] as List).length,
                            (i) {
                              final grade = student['grades'][i];
                              return ListTile(
                                leading: const Icon(Icons.school),
                                title: Text(grade['subjectName'] ?? 'Unknown'),
                                trailing: Text(
                                  '${grade['score']}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue,
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
    );
  }
}
