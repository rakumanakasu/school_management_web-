import 'package:flutter/material.dart';
import '../services/api_service.dart';

class GradesScreen extends StatefulWidget {
  final ApiService apiService;
  const GradesScreen({super.key, required this.apiService});

  @override
  State<GradesScreen> createState() => _GradesScreenState();
}

class _GradesScreenState extends State<GradesScreen> {
  List<dynamic> students = [];
  List<dynamic> subjects = [];
  List<dynamic> grades = [];

  final TextEditingController _scoreController = TextEditingController();
  dynamic selectedStudent;
  dynamic selectedSubject;
  int? editingId;
  bool isLoading = false;

  int currentPage = 0;
  int totalPages = 1;
  final int pageSize = 5;

  @override
  void initState() {
    super.initState();
    loadInitialData();
  }

  Future<void> loadInitialData() async {
    await fetchStudents();
    await fetchSubjects();
    await fetchGrades();
  }

  Future<void> fetchStudents() async {
    try {
      final list = await widget.apiService.getStudents();
      setState(() {
        students = list;
        selectedStudent ??= students.isNotEmpty ? students.first : null;
      });
    } catch (e) {
      _showSnack('Failed to load students: $e');
    }
  }

  Future<void> fetchSubjects() async {
    try {
      final list = await widget.apiService.getSubjects();
      setState(() {
        subjects = list;
        selectedSubject ??= subjects.isNotEmpty ? subjects.first : null;
      });
    } catch (e) {
      _showSnack('Failed to load subjects: $e');
    }
  }

  Future<void> fetchGrades() async {
    setState(() => isLoading = true);
    try {
      final response = await widget.apiService.getAllGrades(page: currentPage, size: pageSize);
      setState(() {
        grades = response['content'] ?? [];
        totalPages = response['totalPages'] ?? 1;
      });
    } catch (e) {
      _showSnack('Failed to load grades: $e');
    }
    setState(() => isLoading = false);
  }

  Future<void> saveGrade() async {
    if (_scoreController.text.trim().isEmpty ||
        selectedStudent == null ||
        selectedSubject == null) {
      _showSnack('Please fill all fields');
      return;
    }

    final data = {
      "score": double.tryParse(_scoreController.text.trim()) ?? 0,
      "student": {"id": selectedStudent['id']},
      "subject": {"id": selectedSubject['id']}
    };

    try {
      if (editingId == null) {
        await widget.apiService.createGrade(data);
        _showSnack('Grade created successfully!');
      } else {
        await widget.apiService.updateGrade(editingId!, data);
        _showSnack('Grade updated successfully!');
      }

      _scoreController.clear();
      editingId = null;
      fetchGrades();
    } catch (e) {
      _showSnack('Error saving grade: $e');
    }
  }

  void _showSnack(String msg) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

  void nextPage() {
    if (currentPage < totalPages - 1) setState(() => currentPage++); fetchGrades();
  }

  void prevPage() {
    if (currentPage > 0) setState(() => currentPage--); fetchGrades();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600;

    return Scaffold(
      appBar: AppBar(title: const Text("Grades"), centerTitle: true),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Responsive Form
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      SizedBox(
                        width: isSmallScreen ? screenWidth : 200,
                        child: DropdownButtonFormField<dynamic>(
                          initialValue: selectedStudent,
                          items: students.map((s) => DropdownMenuItem(
                              value: s,
                              child: Text("${s['firstName']} ${s['lastName']}"))).toList(),
                          onChanged: (val) => setState(() => selectedStudent = val),
                          decoration: const InputDecoration(
                            labelText: 'Student',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      SizedBox(
                        width: isSmallScreen ? screenWidth : 200,
                        child: DropdownButtonFormField<dynamic>(
                          initialValue: selectedSubject,
                          items: subjects.map((s) => DropdownMenuItem(
                              value: s, child: Text(s['subjectName']))).toList(),
                          onChanged: (val) => setState(() => selectedSubject = val),
                          decoration: const InputDecoration(
                            labelText: 'Subject',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      SizedBox(
                        width: isSmallScreen ? screenWidth : 100,
                        child: TextField(
                          controller: _scoreController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Score',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      ElevatedButton(
                        onPressed: saveGrade,
                        child: Text(editingId == null ? 'Add' : 'Update'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Responsive List/Grid
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        if (isSmallScreen) {
                          return ListView.builder(
                            itemCount: grades.length,
                            itemBuilder: (context, index) {
                              final grade = grades[index];
                              return Card(
                                child: ListTile(
                                  title: Text(
                                      'Score: ${grade['score']} (${grade['studentName'] ?? ''})'),
                                  subtitle: Text('Subject: ${grade['subjectName'] ?? ''}'),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                          icon: const Icon(Icons.edit, color: Colors.blue),
                                          onPressed: () {
                                            setState(() {
                                              editingId = grade['id'];
                                              _scoreController.text = grade['score'].toString();
                                            });
                                          }),
                                      IconButton(
                                          icon: const Icon(Icons.delete, color: Colors.red),
                                          onPressed: () => widget.apiService.deleteGrade(grade['id']).then((_) => fetchGrades())),
                                    ],
                                  ),
                                ),
                              );
                            },
                          );
                        } else {
                          final crossCount = constraints.maxWidth ~/ 300;
                          return GridView.builder(
                            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: crossCount > 1 ? crossCount : 1,
                              mainAxisSpacing: 10,
                              crossAxisSpacing: 10,
                              childAspectRatio: 3,
                            ),
                            itemCount: grades.length,
                            itemBuilder: (context, index) {
                              final grade = grades[index];
                              return Card(
                                child: ListTile(
                                  title: Text(
                                      'Score: ${grade['score']} (${grade['studentName'] ?? ''})'),
                                  subtitle: Text('Subject: ${grade['subjectName'] ?? ''}'),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                          icon: const Icon(Icons.edit, color: Colors.blue),
                                          onPressed: () {
                                            setState(() {
                                              editingId = grade['id'];
                                              _scoreController.text = grade['score'].toString();
                                            });
                                          }),
                                      IconButton(
                                          icon: const Icon(Icons.delete, color: Colors.red),
                                          onPressed: () => widget.apiService.deleteGrade(grade['id']).then((_) => fetchGrades())),
                                    ],
                                  ),
                                ),
                              );
                            },
                          );
                        }
                      },
                    ),
                  ),

                  // Pagination
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton(onPressed: currentPage > 0 ? prevPage : null, child: const Text("Previous")),
                      const SizedBox(width: 20),
                      Text('Page ${currentPage + 1} of $totalPages'),
                      const SizedBox(width: 20),
                      ElevatedButton(onPressed: currentPage < totalPages - 1 ? nextPage : null, child: const Text("Next")),
                    ],
                  ),
                ],
              ),
            ),
    );
  }
}
