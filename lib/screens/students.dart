import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';
import 'student_detail_screen.dart';

class StudentsScreen extends StatefulWidget {
  final ApiService apiService;
  final String? userEmail;

  const StudentsScreen({
    super.key,
    required this.apiService,
    this.userEmail,
  });

  @override
  State<StudentsScreen> createState() => _StudentsScreenState();
}

class _StudentsScreenState extends State<StudentsScreen> {
  List<dynamic> students = [];
  List<Map<String, dynamic>> classrooms = [];
  final TextEditingController searchController = TextEditingController();

  int currentPage = 0;
  int totalPages = 1;
  final int pageSize = 5;
  bool isLoading = false;

  final TextEditingController firstNameController = TextEditingController();
  final TextEditingController lastNameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController addressController = TextEditingController();
  DateTime? selectedDob;
  String selectedGender = 'Male';
  int? selectedClassId;

  XFile? pickedFile;
  Uint8List? webImage;
  File? fileImage;

  int? editingId;

  @override
  void initState() {
    super.initState();
    fetchClassrooms();
    fetchStudents();
  }

  /// ---------------- Fetch classrooms ----------------
  Future<void> fetchClassrooms() async {
    try {
      final data = await widget.apiService.getClassrooms();
      setState(() {
        classrooms = data.map((cls) {
          return {
            'id': int.parse(cls['id'].toString()),
            'className': cls['className']
          };
        }).toList();
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load classrooms: $e')),
      );
    }
  }

  /// ---------------- Fetch students ----------------
  Future<void> fetchStudents({String? query}) async {
    setState(() => isLoading = true);
    try {
      if (widget.userEmail != null) {
        final student =
            await widget.apiService.getStudentByEmail(widget.userEmail!);
        setState(() {
          students = [student];
          totalPages = 1;
        });
      } else {
        final response = await widget.apiService.getAllStudents(
          page: currentPage,
          size: pageSize,
          searchQuery: searchController.text.trim(),
        );
        setState(() {
          students = response['content'];
          totalPages = response['totalPages'];
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load students: $e')),
      );
    }
    setState(() => isLoading = false);
  }

  /// ---------------- Pick image ----------------
  Future<void> pickImage() async {
    final ImagePicker picker = ImagePicker();
    final result = await picker.pickImage(source: ImageSource.gallery);
    if (result != null) {
      if (kIsWeb) {
        final bytes = await result.readAsBytes();
        setState(() {
          pickedFile = result;
          webImage = bytes;
        });
      } else {
        setState(() {
          fileImage = File(result.path);
        });
      }
    }
  }

  /// ---------------- Show student form ----------------
  Future<void> showStudentForm({Map<String, dynamic>? student}) async {
    if (student != null) {
      // Populate fields from full student detail
      editingId = student['id'];
      firstNameController.text = student['firstName'] ?? '';
      lastNameController.text = student['lastName'] ?? '';
      emailController.text = student['email'] ?? '';
      addressController.text = student['address'] ?? '';
      selectedGender = student['gender'] ?? 'Male';
      selectedDob =
          student['dob'] != null ? DateTime.tryParse(student['dob']) : null;
      selectedClassId = student['classroom'] != null
          ? int.parse(student['classroom']['id'].toString())
          : null;

      // Load existing photo
      if (student['photo'] != null) {
        if (kIsWeb) {
          // For web, you might need to fetch bytes separately if needed
          webImage = null;
          pickedFile = null;
        } else {
          fileImage = null;
        }
      }
    } else {
      // Clear all fields for new student
      editingId = null;
      firstNameController.clear();
      lastNameController.clear();
      emailController.clear();
      addressController.clear();
      selectedGender = 'Male';
      selectedDob = null;
      selectedClassId = null;
      pickedFile = null;
      webImage = null;
      fileImage = null;
    }

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(student == null ? 'Add Student' : 'Edit Student'),
        content: SingleChildScrollView(
          child: Column(
            children: [
              TextField(
                controller: firstNameController,
                decoration: const InputDecoration(labelText: 'First Name'),
              ),
              TextField(
                controller: lastNameController,
                decoration: const InputDecoration(labelText: 'Last Name'),
              ),
              TextField(
                controller: emailController,
                decoration: const InputDecoration(labelText: 'Email'),
              ),
              TextField(
                controller: addressController,
                decoration: const InputDecoration(labelText: 'Address'),
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                value: selectedGender,
                items: const [
                  DropdownMenuItem(value: 'Male', child: Text('Male')),
                  DropdownMenuItem(value: 'Female', child: Text('Female')),
                ],
                onChanged: (val) => setState(() => selectedGender = val!),
                decoration: const InputDecoration(labelText: 'Gender'),
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<int>(
                value: selectedClassId,
                items: classrooms.map((cls) {
                  return DropdownMenuItem<int>(
                    value: cls['id'],
                    child: Text(cls['className']),
                  );
                }).toList(),
                onChanged: (val) => setState(() => selectedClassId = val),
                decoration: const InputDecoration(labelText: 'Classroom'),
              ),
              const SizedBox(height: 10),
              InkWell(
                onTap: () async {
                  final dob = await showDatePicker(
                    context: context,
                    initialDate: selectedDob ?? DateTime(2000),
                    firstDate: DateTime(1950),
                    lastDate: DateTime.now(),
                  );
                  if (dob != null) setState(() => selectedDob = dob);
                },
                child: InputDecorator(
                  decoration: const InputDecoration(labelText: 'Date of Birth'),
                  child: Text(selectedDob != null
                      ? DateFormat('yyyy-MM-dd').format(selectedDob!)
                      : 'Select date'),
                ),
              ),
              const SizedBox(height: 10),
              ElevatedButton.icon(
                onPressed: pickImage,
                icon: const Icon(Icons.image),
                label: const Text('Pick Photo'),
              ),
              if (pickedFile != null || fileImage != null)
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: kIsWeb
                      ? Image.memory(webImage!, height: 80)
                      : Image.file(fileImage!, height: 80),
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final data = {
                'firstName': firstNameController.text,
                'lastName': lastNameController.text,
                'email': emailController.text,
                'address': addressController.text,
                'gender': selectedGender,
                if (selectedDob != null)
                  'dob': DateFormat('yyyy-MM-dd').format(selectedDob!),
                if (selectedClassId != null) 'classroomId': selectedClassId,
              };

              try {
                if (editingId == null) {
                  await widget.apiService.createStudentMultipart(
                    data,
                    fileImage,
                    pickedFile: pickedFile,
                    webBytes: webImage,
                  );
                  ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Student created!')));
                } else {
                  await widget.apiService.updateStudentMultipart(
                    editingId!,
                    data,
                    fileImage,
                    pickedFile: pickedFile,
                    webBytes: webImage,
                  );
                  ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Student updated!')));
                }
                Navigator.pop(context);
                fetchStudents();
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e')));
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  /// ---------------- Delete student ----------------
  Future<void> deleteStudent(int id) async {
    try {
      await widget.apiService.deleteStudent(id);
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Student deleted!')));
      fetchStudents();
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Delete failed: $e')));
    }
  }

  void _goToPreviousPage() {
    if (currentPage > 0) {
      setState(() => currentPage--);
      fetchStudents();
    }
  }

  void _goToNextPage() {
    if (currentPage < totalPages - 1) {
      setState(() => currentPage++);
      fetchStudents();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isStudentView = widget.userEmail != null;
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600;

    return Scaffold(
      appBar: AppBar(title: const Text('Students')),
      floatingActionButton: isStudentView
          ? null
          : FloatingActionButton(
              onPressed: () => showStudentForm(),
              child: const Icon(Icons.add),
            ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: searchController,
                          decoration: const InputDecoration(
                            labelText: 'Search by name',
                            prefixIcon: Icon(Icons.search),
                            border: OutlineInputBorder(),
                          ),
                          onSubmitted: (_) => fetchStudents(),
                        ),
                      ),
                      const SizedBox(width: 10),
                      ElevatedButton(
                        onPressed: () =>
                            fetchStudents(query: searchController.text),
                        child: const Text('Search'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: LayoutBuilder(builder: (context, constraints) {
                      if (isSmallScreen) {
                        return ListView.builder(
                          itemCount: students.length,
                          itemBuilder: (context, index) {
                            final s = students[index];
                            return _studentCard(s, isStudentView);
                          },
                        );
                      } else {
                        final crossCount = constraints.maxWidth ~/ 300;
                        return GridView.builder(
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: crossCount > 1 ? crossCount : 1,
                            childAspectRatio: 3,
                            crossAxisSpacing: 10,
                            mainAxisSpacing: 10,
                          ),
                          itemCount: students.length,
                          itemBuilder: (context, index) {
                            final s = students[index];
                            return _studentCard(s, isStudentView);
                          },
                        );
                      }
                    }),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton(
                          onPressed:
                              currentPage > 0 ? _goToPreviousPage : null,
                          child: const Text('Previous')),
                      const SizedBox(width: 12),
                      Text('Page ${currentPage + 1} of $totalPages'),
                      const SizedBox(width: 12),
                      ElevatedButton(
                          onPressed: currentPage < totalPages - 1
                              ? _goToNextPage
                              : null,
                          child: const Text('Next')),
                    ],
                  ),
                ],
              ),
            ),
    );
  }

  /// ---------------- Student Card ----------------
  Widget _studentCard(Map<String, dynamic> s, bool isStudentView) {
    return Card(
      elevation: 2,
      child: ListTile(
        leading: CircleAvatar(
          backgroundImage:
              s['photo'] != null ? NetworkImage(s['photo']) : null,
          child: s['photo'] == null ? const Icon(Icons.person) : null,
        ),
        title: Text('${s['firstName']} ${s['lastName']}'),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(s['email'] ?? '-'),
            if (s['classroom'] != null) Text('Class: ${s['classroom']['className']}')
          ],
        ),
        onTap: () async {
          try {
            final detail = await widget.apiService.getStudentDetail(s['id']);
            if (context.mounted) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => StudentDetailScreen(
                    apiService: widget.apiService,
                    student: detail,
                  ),
                ),
              );
            }
          } catch (e) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Failed to load details: $e')),
            );
          }
        },
        trailing: isStudentView
            ? null
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit, color: Colors.blue),
                    onPressed: () async {
                      try {
                        final detail = await widget.apiService
                            .getStudentDetail(s['id']);
                        showStudentForm(student: detail);
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                              content:
                                  Text('Failed to load student details: $e')),
                        );
                      }
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => deleteStudent(s['id']),
                  ),
                ],
              ),
      ),
    );
  }
}
