import 'package:flutter/material.dart';
import '../services/api_service.dart';

class DashboardScreen extends StatefulWidget {
  final ApiService apiService;

  const DashboardScreen({super.key, required this.apiService});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text('Dashboard'),
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: widget.apiService.getDashboardStats(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Error: ${snapshot.error}',
                style: const TextStyle(color: Colors.red),
              ),
            );
          }

          final data = snapshot.data ?? {};
          final warning = data['warning'] as String?;
          final roles = (data['role'] as List<dynamic>?)?.cast<String>() ?? [];

          final normalizedRoles = roles
              .map((r) => r.replaceFirst("ROLE_", "").toUpperCase())
              .toList();

          final isAdmin = normalizedRoles.contains("ADMIN");
          final isTeacher = normalizedRoles.contains("TEACHER");
          final isStudent = normalizedRoles.contains("STUDENT");

          final studentsCount = _toInt(data['students']);
          final teachersCount = _toInt(data['teachers']);
          final gradesCount = _toInt(data['grades']);
          final attendanceCount = _toInt(data['attendance']);
          final absentCount = _toInt(data['absentCount']);

          final List<Widget> cards = [];

          if (isAdmin) {
            cards.addAll([
              _buildCard('Students', studentsCount, Colors.blue, Icons.group),
              _buildCard('Teachers', teachersCount, Colors.green, Icons.person),
              _buildCard('Grades', gradesCount, Colors.orange, Icons.grade),
              _buildCard('Attendance', attendanceCount, Colors.red, Icons.event_available),
              _buildCard('Absent', absentCount, Colors.purple, Icons.event_busy),
            ]);
          } else if (isTeacher) {
            cards.addAll([
              _buildCard('Students', studentsCount, Colors.blue, Icons.group),
              _buildCard('Grades', gradesCount, Colors.orange, Icons.grade),
              _buildCard('Attendance', attendanceCount, Colors.red, Icons.event_available),
              _buildCard('Absent', absentCount, Colors.purple, Icons.event_busy),
            ]);
          } else if (isStudent) {
            cards.addAll([
              _buildCard('Attendance', attendanceCount, Colors.red, Icons.event_available),
              _buildCard('Absent', absentCount, Colors.purple, Icons.event_busy),
            ]);
          } else {
            cards.add(_buildCard('No role assigned', 0, Colors.grey, Icons.error_outline));
          }

          // Responsive grid count
          int crossAxisCount = 2;
          if (screenWidth < 400) crossAxisCount = 1;
          if (screenWidth >= 800) crossAxisCount = 3;
          if (screenWidth >= 1200) crossAxisCount = 4;

          // Aspect ratio – make smaller to avoid overflow
          double childAspectRatio = 2.5;
          if (screenWidth >= 600) childAspectRatio = 2.0;
          if (screenWidth >= 1200) childAspectRatio = 1.6;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(10),
            child: Column(
              children: [
                if (warning != null && warning.isNotEmpty) ...[
                  Card(
                    color: Colors.redAccent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Row(
                        children: [
                          const Icon(Icons.warning, color: Colors.white),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              warning,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: cards.length,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                    childAspectRatio: childAspectRatio,
                  ),
                  itemBuilder: (context, index) => cards[index],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  int _toInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  Widget _buildCard(String title, int value, Color color, IconData icon) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: color.withOpacity(0.85),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 6),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(height: 2),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 2),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                value.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
