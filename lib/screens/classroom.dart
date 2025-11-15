import 'package:flutter/material.dart';
import '../services/api_service.dart';

class ClassroomScreen extends StatefulWidget {
  final ApiService apiService;
  final String currentUserRole; // Role of logged-in user

  const ClassroomScreen({
    super.key,
    required this.apiService,
    required this.currentUserRole,
  });

  @override
  State<ClassroomScreen> createState() => _ClassroomScreenState();
}

class _ClassroomScreenState extends State<ClassroomScreen> {
  List<Map<String, dynamic>> classrooms = [];
  List<Map<String, dynamic>> teachers = [];
  Map<String, dynamic>? selectedTeacher;
  bool isLoading = true;

  bool get isAdmin => widget.currentUserRole == 'ADMIN';

  @override
  void initState() {
    super.initState();
    _loadClassrooms();
    if (isAdmin) _loadTeachers();
  }

  Future<void> _loadClassrooms() async {
    setState(() => isLoading = true);
    try {
      final data = await widget.apiService.getClassrooms();
      setState(() => classrooms = data);
    } catch (e) {
      _showMessage('Failed to load classrooms: $e');
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _loadTeachers() async {
    try {
      final data = await widget.apiService.getTeachers();
      setState(() => teachers = data);
    } catch (e) {
      _showMessage('Failed to load teachers: $e');
    }
  }

  void _showMessage(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _deleteClassroom(int id) async {
    try {
      await widget.apiService.deleteClassroom(id);
      _showMessage('Classroom deleted');
      await _loadClassrooms();
    } catch (e) {
      _showMessage('Failed to delete: $e');
    }
  }

  Future<void> _showClassroomForm({Map<String, dynamic>? classroom}) async {
    final formKey = GlobalKey<FormState>();
    final TextEditingController nameController =
        TextEditingController(text: classroom?['className'] ?? '');
    final TextEditingController roomController =
        TextEditingController(text: classroom?['roomNumber'] ?? '');

    // Set selectedTeacher for editing
    if (classroom != null && classroom['teacher'] != null) {
      final teacherId = classroom['teacher']['id'];
      selectedTeacher = teachers.cast<Map<String, dynamic>>().firstWhere(
        (t) => t['id'] == teacherId,
        orElse: () => {},
      );
      if (selectedTeacher!.isEmpty) selectedTeacher = null;
    } else {
      selectedTeacher = null;
    }

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(classroom == null ? 'Create Classroom' : 'Update Classroom'),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Class Name'),
                  validator: (value) =>
                      value == null || value.isEmpty ? 'Enter class name' : null,
                  enabled: isAdmin || classroom == null,
                ),
                TextFormField(
                  controller: roomController,
                  decoration: const InputDecoration(labelText: 'Room Number'),
                  validator: (value) =>
                      value == null || value.isEmpty ? 'Enter room number' : null,
                  enabled: isAdmin || classroom == null,
                ),
                if (isAdmin) ...[
                  const SizedBox(height: 10),
                  DropdownButtonFormField<Map<String, dynamic>>(
                    value: selectedTeacher,
                    items: teachers
                        .map((t) => DropdownMenuItem(
                              value: t,
                              child: Text('${t['firstName']} ${t['lastName']}'),
                            ))
                        .toList(),
                    onChanged: (val) => setState(() => selectedTeacher = val),
                    decoration: const InputDecoration(labelText: 'Teacher'),
                  ),
                ],
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          if (isAdmin)
            ElevatedButton(
              onPressed: () async {
                if (!formKey.currentState!.validate()) return;

                final data = {
                  'name': nameController.text.trim(),
                  'roomNumber': roomController.text.trim(),
                  'teacherId': selectedTeacher?['id'],
                };

                try {
                  if (classroom == null) {
                    await widget.apiService.createClassroom(data);
                    _showMessage('Classroom created');
                  } else {
                    await widget.apiService.updateClassroom(classroom['id'], data);
                    _showMessage('Classroom updated');
                  }
                  Navigator.pop(context);
                  await _loadClassrooms();
                } catch (e) {
                  _showMessage('Failed: $e');
                }
              },
              child: Text(classroom == null ? 'Create' : 'Update'),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Classrooms'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadClassrooms),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : classrooms.isEmpty
              ? const Center(child: Text('No classrooms found'))
              : ListView.builder(
                  itemCount: classrooms.length,
                  itemBuilder: (context, index) {
                    final classroom = classrooms[index];
                    return Card(
                      margin: const EdgeInsets.all(8),
                      child: ListTile(
                        title: Text(classroom['className'] ?? 'Unknown'),
                        subtitle: Text(
                          'Room: ${classroom['roomNumber'] ?? '-'}'
                          '${isAdmin ? '\nTeacher ID: ${classroom['teacher']?['id'] ?? '-'}\nTeacher Name: ${classroom['teacher']?['firstName'] ?? '-'} ${classroom['teacher']?['lastName'] ?? '-'}' : ''}',
                        ),
                        isThreeLine: true,
                        trailing: isAdmin
                            ? Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit, color: Colors.blue),
                                    onPressed: () => _showClassroomForm(classroom: classroom),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete, color: Colors.red),
                                    onPressed: () => _deleteClassroom(classroom['id']),
                                  ),
                                ],
                              )
                            : null,
                      ),
                    );
                  },
                ),
      floatingActionButton: isAdmin
          ? FloatingActionButton(
              child: const Icon(Icons.add),
              onPressed: () => _showClassroomForm(),
            )
          : null,
    );
  }
}
