
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:school_management_frontend/screens/TeacherDetailScreen';
import '../services/api_service.dart';

class TeachersScreen extends StatefulWidget {
  final ApiService apiService;

  const TeachersScreen({super.key, required this.apiService});

  @override
  State<TeachersScreen> createState() => _TeachersScreenState();
}

class _TeachersScreenState extends State<TeachersScreen> {
  List<dynamic> teachers = [];
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadTeachers();
  }

  Future<void> _loadTeachers() async {
    setState(() => isLoading = true);
    try {
      final fetchedTeachers = await widget.apiService.getAllTeachers();
      setState(() => teachers = fetchedTeachers);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to load teachers: $e')));
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _deleteTeacher(int id) async {
    try {
      await widget.apiService.deleteTeacher(id);
      _loadTeachers();
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to delete teacher: $e')));
    }
  }

  Future<void> _openTeacherForm({Map<String, dynamic>? teacher}) async {
    final TextEditingController firstNameController = TextEditingController(
      text: teacher?['firstName'] ?? '',
    );
    final TextEditingController lastNameController = TextEditingController(
      text: teacher?['lastName'] ?? '',
    );
    final TextEditingController emailController = TextEditingController(
      text: teacher?['email'] ?? '',
    );
    final TextEditingController addressController = TextEditingController(
      text: teacher?['address'] ?? '',
    );
    final TextEditingController salaryController = TextEditingController(
      text: teacher?['salary']?.toString() ?? '',
    );

    String selectedGender = teacher?['gender'] ?? 'Male';
    DateTime? selectedDob = teacher?['dob'] != null
        ? DateTime.tryParse(teacher?['dob'])
        : null;

    XFile? pickedFile;
    Uint8List? webBytes;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(teacher == null ? 'Create Teacher' : 'Edit Teacher'),
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
                TextField(
                  controller: salaryController,
                  decoration: const InputDecoration(labelText: 'Salary'),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  initialValue: selectedGender,
                  decoration: const InputDecoration(labelText: 'Gender'),
                  items: ['Male', 'Female', 'Other']
                      .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                      .toList(),
                  onChanged: (value) {
                    if (value != null) setState(() => selectedGender = value);
                  },
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: TextEditingController(
                    text: selectedDob != null
                        ? selectedDob?.toIso8601String().split('T')[0]
                        : '',
                  ),
                  readOnly: true,
                  decoration: const InputDecoration(labelText: 'Date of Birth'),
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: selectedDob ?? DateTime(1990),
                      firstDate: DateTime(1950),
                      lastDate: DateTime.now(),
                    );
                    if (picked != null) setState(() => selectedDob = picked);
                  },
                ),
                const SizedBox(height: 10),
                ElevatedButton(
                  child: const Text('Select Photo'),
                  onPressed: () async {
                    final picker = ImagePicker();
                    pickedFile = await picker.pickImage(
                      source: ImageSource.gallery,
                    );
                    if (kIsWeb && pickedFile != null) {
                      webBytes = await pickedFile?.readAsBytes();
                    }
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final data = {
                  'firstName': firstNameController.text,
                  'lastName': lastNameController.text,
                  'email': emailController.text,
                  'address': addressController.text,
                  'salary': double.tryParse(salaryController.text) ?? 0.0,
                  'gender': selectedGender,
                  'dob': selectedDob != null
                      ? selectedDob?.toIso8601String().split('T')[0]
                      : null,
                };

                try {
                  if (teacher == null) {
                    await widget.apiService.createTeacherMultipart(
                      data,
                      file: null,
                      pickedFile: pickedFile,
                      webBytes: webBytes,
                    );
                  } else {
                    await widget.apiService.updateTeacherMultipart(
                      teacher['id'],
                      data,
                      file: null,
                      pickedFile: pickedFile,
                      webBytes: webBytes,
                    );
                  }
                  Navigator.pop(context);
                  _loadTeachers();
                } catch (e) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text('Error: $e')));
                }
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ElevatedButton(
          onPressed: () => _openTeacherForm(),
          child: const Text('Add Teacher'),
        ),
        Expanded(
          child: isLoading
              ? const Center(child: CircularProgressIndicator())
              : ListView.builder(
                  itemCount: teachers.length,
                  itemBuilder: (context, index) {
                    final teacher = teachers[index];
                    return ListTile(
                      leading:
                          (teacher['photo'] != null && teacher['photo'] != '')
                          ? Image.network(
                              teacher['photo'],
                              width: 50,
                              height: 50,
                              fit: BoxFit.cover,
                            )
                          : const Icon(Icons.person),
                      title: Text(
                        '${teacher['firstName']} ${teacher['lastName']}',
                      ),
                      subtitle: Text('Email: ${teacher['email']}'),
                      onTap: () {
                        // Navigate to detail page
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                TeacherDetailScreen(teacher: teacher),
                          ),
                        );
                      },
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.visibility),
                            tooltip: 'View Details',
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      TeacherDetailScreen(teacher: teacher),
                                ),
                              );
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.edit),
                            tooltip: 'Edit',
                            onPressed: () => _openTeacherForm(teacher: teacher),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete),
                            tooltip: 'Delete',
                            onPressed: () => _deleteTeacher(teacher['id']),
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
