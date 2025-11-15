import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';

class AttendanceScreen extends StatefulWidget {
  final ApiService apiService;
  final String role; // ADMIN, TEACHER, STUDENT

  const AttendanceScreen({super.key, required this.apiService, required this.role});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  List<Map<String, dynamic>> classrooms = [];
  Map<String, dynamic>? selectedClassroom;

  List<Map<String, dynamic>> students = [];
  bool loading = false;

  // Pagination
  int currentPage = 0;
  int totalPages = 1;
  final int pageSize = 5;
  String searchQuery = '';

  @override
  void initState() {
    super.initState();
    fetchClassrooms();
  }

  Future<void> fetchClassrooms() async {
    try {
      final data = await widget.apiService.getClassrooms();
      setState(() => classrooms = data);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching classes: $e')),
      );
    }
  }

  Future<void> fetchAttendances(int classId, {int page = 0, String? search}) async {
    setState(() => loading = true);
    try {
      final response = await widget.apiService.getAttendancesByClassIdPaged(
        classId: classId,
        page: page,
        size: pageSize,
        search: search,
      );

      setState(() {
        students = List<Map<String, dynamic>>.from(response['students'] ?? []);
        currentPage = response['currentPage'] ?? 0;
        totalPages = response['totalPages'] ?? 1;
      });
    } catch (e) {
      setState(() {
        students = [];
        currentPage = 0;
        totalPages = 1;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching attendances: $e')),
      );
    } finally {
      setState(() => loading = false);
    }
  }

  Future<void> updateAttendance(Map<String, dynamic> attendance) async {
    try {
      await widget.apiService.updateAttendance(attendance['id'], attendance['present']);
      if (selectedClassroom != null) {
        fetchAttendances(selectedClassroom!['id'], page: currentPage, search: searchQuery);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to update: $e')));
    }
  }

  void _showAddAttendanceDialog() async {
    if (selectedClassroom == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a class first')));
      return;
    }

    List<Map<String, dynamic>> allStudents = [];
    List<Map<String, dynamic>> allSubjects = [];

    try {
      allStudents = await widget.apiService.getStudentsByClassId(selectedClassroom!['id']);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to load students: $e')));
      return;
    }

    try {
      allSubjects = await widget.apiService.getSubjectsByClassId(selectedClassroom!['id']);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to load subjects: $e')));
      return;
    }

    if (allStudents.isEmpty || allSubjects.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No students or subjects available for this class')),
      );
      return;
    }

    Map<String, dynamic> selectedStudent = allStudents.first;
    Map<String, dynamic> selectedSubject = allSubjects.first;
    String selectedStatus = "Present";
    DateTime selectedDate = DateTime.now();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Attendance'),
        content: StatefulBuilder(
          builder: (context, setStateDialog) => SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButton<Map<String, dynamic>>(
                  value: selectedStudent,
                  hint: const Text('Select Student'),
                  isExpanded: true,
                  items: allStudents
                      .map((s) => DropdownMenuItem(value: s, child: Text('${s['firstName']} ${s['lastName']}')))
                      .toList(),
                  onChanged: (val) => setStateDialog(() => selectedStudent = val!),
                ),
                const SizedBox(height: 10),
                DropdownButton<Map<String, dynamic>>(
                  value: selectedSubject,
                  hint: const Text('Select Subject'),
                  isExpanded: true,
                  items: allSubjects
                      .map((s) => DropdownMenuItem(value: s, child: Text(s['name'] ?? '')))
                      .toList(),
                  onChanged: (val) => setStateDialog(() => selectedSubject = val!),
                ),
                const SizedBox(height: 10),
                DropdownButton<String>(
                  value: selectedStatus,
                  isExpanded: true,
                  items: ["Present", "Absent"].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                  onChanged: (val) {
                    if (val != null) setStateDialog(() => selectedStatus = val);
                  },
                ),
                const SizedBox(height: 10),
                TextButton(
                  onPressed: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: selectedDate,
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2100),
                    );
                    if (picked != null) setStateDialog(() => selectedDate = picked);
                  },
                  child: Text('Select Date: ${DateFormat('yyyy-MM-dd').format(selectedDate)}'),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              try {
                await widget.apiService.createAttendance(
                  studentId: selectedStudent['id'],
                  subjectId: selectedSubject['id'],
                  present: selectedStatus == "Present",
                  date: DateFormat('yyyy-MM-dd').format(selectedDate),
                );

                Navigator.pop(context);
                if (selectedClassroom != null) {
                  fetchAttendances(selectedClassroom!['id'], page: currentPage, search: searchQuery);
                }
              } catch (e) {
                ScaffoldMessenger.of(context)
                    .showSnackBar(SnackBar(content: Text('Failed to add attendance: $e')));
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  Widget _buildDataTable() {
    List<DataRow> rows = [];
    for (var student in students) {
      final attendances = (student['attendances'] as List<dynamic>?) ?? [];
      for (var att in attendances) {
        rows.add(DataRow(
          cells: [
            DataCell(Text('${student['firstName']} ${student['lastName']}')),
            DataCell(Text(student['className'] ?? '')),
            DataCell(Text(att['subjectName'] ?? '')),
            DataCell(DropdownButton<bool>(
              value: att['present'],
              items: const [
                DropdownMenuItem(value: true, child: Text('Present')),
                DropdownMenuItem(value: false, child: Text('Absent')),
              ],
              onChanged: widget.role == 'ADMIN'
                  ? (val) {
                      if (val != null) {
                        setState(() => att['present'] = val);
                        updateAttendance(att);
                      }
                    }
                  : null,
            )),
            DataCell(TextButton(
              child: Text(DateFormat('yyyy-MM-dd')
                  .format(DateTime.parse(att['date'] ?? DateTime.now().toString()))),
              onPressed: widget.role == 'ADMIN'
                  ? () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: DateTime.parse(att['date']),
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2100),
                      );
                      if (picked != null) {
                        setState(() {
                          att['date'] = DateFormat('yyyy-MM-dd').format(picked);
                        });
                        updateAttendance(att);
                      }
                    }
                  : null,
            )),
            DataCell(widget.role == 'ADMIN'
                ? IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () async {
                      try {
                        await widget.apiService.deleteAttendance(att['id']);
                        if (selectedClassroom != null) {
                          fetchAttendances(selectedClassroom!['id'], page: currentPage, search: searchQuery);
                        }
                      } catch (e) {
                        ScaffoldMessenger.of(context)
                            .showSnackBar(SnackBar(content: Text('Failed to delete: $e')));
                      }
                    },
                  )
                : const SizedBox()),
          ],
        ));
      }
    }
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columnSpacing: 20,
        columns: const [
          DataColumn(label: Text('Student')),
          DataColumn(label: Text('Class')),
          DataColumn(label: Text('Subject')),
          DataColumn(label: Text('Status')),
          DataColumn(label: Text('Date')),
          DataColumn(label: Text('Actions')),
        ],
        rows: rows,
      ),
    );
  }

  Widget _buildPaginationControls() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: currentPage > 0
              ? () {
                  if (selectedClassroom != null) {
                    fetchAttendances(selectedClassroom!['id'], page: currentPage - 1, search: searchQuery);
                  }
                }
              : null,
        ),
        Text('Page ${currentPage + 1} of $totalPages'),
        IconButton(
          icon: const Icon(Icons.arrow_forward),
          onPressed: currentPage < totalPages - 1
              ? () {
                  if (selectedClassroom != null) {
                    fetchAttendances(selectedClassroom!['id'], page: currentPage + 1, search: searchQuery);
                  }
                }
              : null,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Attendance')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: DropdownButton<Map<String, dynamic>>(
                    hint: const Text('Select Class'),
                    value: selectedClassroom,
                    isExpanded: true,
                    items: classrooms
                        .map((c) => DropdownMenuItem(value: c, child: Text(c['className'] ?? '')))
                        .toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() {
                          selectedClassroom = val;
                          currentPage = 0;
                          searchQuery = '';
                        });
                        fetchAttendances(val['id'], page: 0);
                      }
                    },
                  ),
                ),
                const SizedBox(width: 10),
                if (widget.role == 'ADMIN')
                  ElevatedButton(onPressed: _showAddAttendanceDialog, child: const Text('Add Attendance')),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: TextField(
              decoration: const InputDecoration(labelText: 'Search by student', prefixIcon: Icon(Icons.search)),
              onSubmitted: (value) {
                searchQuery = value.trim();
                if (selectedClassroom != null) {
                  fetchAttendances(selectedClassroom!['id'], page: 0, search: searchQuery);
                }
              },
            ),
          ),
          Expanded(
            child: loading
                ? const Center(child: CircularProgressIndicator())
                : students.isEmpty
                    ? const Center(child: Text('No attendance records'))
                    : Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Column(
                          children: [
                            Expanded(child: _buildDataTable()),
                            _buildPaginationControls(),
                          ],
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}
