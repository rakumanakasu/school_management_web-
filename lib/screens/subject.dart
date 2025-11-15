import 'package:flutter/material.dart';
import '../services/api_service.dart';

class SubjectScreen extends StatefulWidget {
  final ApiService apiService;
  const SubjectScreen({super.key, required this.apiService});

  @override
  State<SubjectScreen> createState() => _SubjectScreenState();
}

class _SubjectScreenState extends State<SubjectScreen> {
  List<dynamic> subjects = [];
  List<String> classes = [];
  final TextEditingController _nameController = TextEditingController();
  String? selectedClass;
  final TextEditingController _searchController = TextEditingController();
  int? editingId;
  bool isLoading = false;

  // Pagination
  int currentPage = 0;
  int totalPages = 1;
  final int pageSize = 5;

  @override
  void initState() {
    super.initState();
    fetchClasses();
    fetchSubjects();
  }

  Future<void> fetchSubjects({String? query}) async {
    setState(() => isLoading = true);
    try {
      final response = query == null || query.isEmpty
          ? await widget.apiService.getAllSubjects(page: currentPage, size: pageSize)
          : await widget.apiService.searchSubjects(query, page: currentPage, size: pageSize);

      setState(() {
        subjects = response['content'] ?? [];
        totalPages = response['totalPages'] ?? 1;
      });
    } catch (e) {
      _showSnack('Failed to load subjects: $e');
    }
    setState(() => isLoading = false);
  }

  Future<void> fetchClasses() async {
    try {
      final classroomList = await widget.apiService.getClassrooms();
      setState(() {
        classes = classroomList.map((c) => c['className'].toString()).toList();
        if (classes.isNotEmpty) selectedClass = classes.first;
      });
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Failed to load classes: $e')));
    }
  }

  Future<void> saveSubject() async {
    if (_nameController.text.trim().isEmpty || selectedClass == null) {
      _showSnack('Please enter subject name and select class');
      return;
    }

    final data = {
      'subjectName': _nameController.text.trim(),
      'className': selectedClass,
    };

    try {
      if (editingId == null) {
        await widget.apiService.createSubject(data);
        _showSnack('Subject created successfully!');
      } else {
        await widget.apiService.updateSubject(editingId!, data);
        _showSnack('Subject updated successfully!');
      }

      _nameController.clear();
      editingId = null;
      selectedClass = classes.isNotEmpty ? classes.first : null;
      fetchSubjects(query: _searchController.text.trim());
    } catch (e) {
      _showSnack('Error saving subject: $e');
    }
  }

  Future<void> deleteSubject(int id) async {
    try {
      await widget.apiService.deleteSubject(id);
      _showSnack('Subject deleted!');
      fetchSubjects(query: _searchController.text.trim());
    } catch (e) {
      _showSnack('Failed to delete: $e');
    }
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  void _goToPreviousPage() {
    if (currentPage > 0) {
      setState(() => currentPage--);
      fetchSubjects(query: _searchController.text.trim());
    }
  }

  void _goToNextPage() {
    if (currentPage < totalPages - 1) {
      setState(() => currentPage++);
      fetchSubjects(query: _searchController.text.trim());
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Subjects"),
        centerTitle: true,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Responsive Search & Buttons
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      SizedBox(
                        width: isSmallScreen ? screenWidth : 250,
                        child: TextField(
                          controller: _searchController,
                          decoration: const InputDecoration(
                            labelText: 'Search by subject name',
                            prefixIcon: Icon(Icons.search),
                            border: OutlineInputBorder(),
                          ),
                          onSubmitted: (_) =>
                              fetchSubjects(query: _searchController.text.trim()),
                        ),
                      ),
                      ElevatedButton(
                        onPressed: () =>
                            fetchSubjects(query: _searchController.text.trim()),
                        child: const Text("Search"),
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.grey),
                        onPressed: () {
                          _searchController.clear();
                          currentPage = 0;
                          fetchSubjects();
                        },
                        child: const Text("Clear"),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Responsive Add/Update Form
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      SizedBox(
                        width: isSmallScreen ? screenWidth : 200,
                        child: TextField(
                          controller: _nameController,
                          decoration: const InputDecoration(
                            labelText: 'Subject Name',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      SizedBox(
                        width: isSmallScreen ? screenWidth : 200,
                        child: DropdownButtonFormField<String>(
                          initialValue: selectedClass,
                          items: classes.map((cls) {
                            return DropdownMenuItem(
                              value: cls,
                              child: Text(cls),
                            );
                          }).toList(),
                          onChanged: (val) => setState(() => selectedClass = val),
                          decoration: const InputDecoration(
                            labelText: 'Select Class',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      ElevatedButton(
                        onPressed: saveSubject,
                        child: Text(editingId == null ? 'Add' : 'Update'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Responsive Subject List
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        if (isSmallScreen) {
                          return ListView.builder(
                            itemCount: subjects.length,
                            itemBuilder: (context, index) {
                              final subject = subjects[index];
                              return _subjectCard(subject);
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
                            itemCount: subjects.length,
                            itemBuilder: (context, index) {
                              final subject = subjects[index];
                              return _subjectCard(subject);
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
                      ElevatedButton(
                        onPressed: currentPage > 0 ? _goToPreviousPage : null,
                        child: const Text("Previous"),
                      ),
                      const SizedBox(width: 20),
                      Text("Page ${currentPage + 1} of $totalPages"),
                      const SizedBox(width: 20),
                      ElevatedButton(
                        onPressed: currentPage < totalPages - 1 ? _goToNextPage : null,
                        child: const Text("Next"),
                      ),
                    ],
                  ),
                ],
              ),
            ),
    );
  }

  Widget _subjectCard(Map<String, dynamic> subject) {
    return Card(
      elevation: 2,
      child: ListTile(
        title: Text(subject['subjectName']),
        subtitle: Text('Class: ${subject['className'] ?? '-'}'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.blue),
              onPressed: () {
                setState(() {
                  editingId = subject['id'];
                  _nameController.text = subject['subjectName'];
                  selectedClass = subject['className'];
                });
              },
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () => deleteSubject(subject['id']),
            ),
          ],
        ),
      ),
    );
  }
}
