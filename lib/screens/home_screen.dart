import 'package:flutter/material.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import '../services/session_storage_service.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import 'dashboard.dart';
import 'students.dart';
import 'teachers.dart';
import 'grades.dart';
import 'attendance.dart';
import 'subject.dart';
import 'classroom.dart';
import 'user_screen.dart';
import 'login_screen.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int selectedIndex = 0;
  List<String> userRoles = [];
  late ApiService apiService;
  String? userEmail;

  @override
  void initState() {
    super.initState();
    apiService = ApiService(baseUrl: 'http://localhost:8081');
    _loadRoles();
  }

  Future<void> _loadRoles() async {
    final storage = await SessionStorageService.getInstance();
    final token = storage.retrieveAccessToken();

    if (token != null && !JwtDecoder.isExpired(token)) {
      Map<String, dynamic> decoded = JwtDecoder.decode(token);
      setState(() {
        userRoles = List<String>.from(decoded['realm_access']?['roles'] ?? []);
        userEmail = decoded['email'];
      });
    } else {
      _goToLogin();
    }
  }

  Future<void> _logout() async {
  final confirm = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Logout'),
      content: const Text('Are you sure you want to logout?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('No'),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('Yes'),
        ),
      ],
    ),
  );

  if (confirm == true) {
    final authService = await AuthService.getInstance();
    await authService.logout();
    _goToLogin();
  }
}


  void _goToLogin() async {
  final authService = await AuthService.getInstance();
  if (!mounted) return;

  Navigator.pushAndRemoveUntil(
    context,
    MaterialPageRoute(
      builder: (_) => LoginScreen(authService: authService),
    ),
    (route) => false,
  );
}


  @override
  Widget build(BuildContext context) {
    List<NavigationRailDestination> railDestinations = [];
    List<BottomNavigationBarItem> bottomNavItems = [];
    List<Widget> screens = [];
    List<String> titles = [];

    // Dashboard for all roles
    railDestinations.add(const NavigationRailDestination(
        icon: Icon(Icons.dashboard), label: Text('Dashboard')));
    bottomNavItems.add(const BottomNavigationBarItem(
        icon: Icon(Icons.dashboard), label: 'Dashboard'));
    screens.add(DashboardScreen(apiService: apiService));
    titles.add('Dashboard');

    // STUDENT
    if (userRoles.contains('STUDENT')) {
      railDestinations.addAll([
        const NavigationRailDestination(
            icon: Icon(Icons.school), label: Text('Attendance')),
        const NavigationRailDestination(
            icon: Icon(Icons.access_time), label: Text('My Details')),
      ]);
      bottomNavItems.addAll([
        const BottomNavigationBarItem(
            icon: Icon(Icons.school), label: 'Attendance'),
        const BottomNavigationBarItem(
            icon: Icon(Icons.access_time), label: 'My Details'),
      ]);
      screens.addAll([
        AttendanceScreen(apiService: apiService, role: 'STUDENT'),
        StudentsScreen(apiService: apiService)
      ]);
      titles.addAll(['Attendance', 'My Details']);
    }

    // TEACHER
    if (userRoles.contains('TEACHER')) {
      railDestinations.addAll([
        const NavigationRailDestination(
            icon: Icon(Icons.school), label: Text('Students')),
        const NavigationRailDestination(
            icon: Icon(Icons.meeting_room), label: Text('Classrooms')),
        const NavigationRailDestination(
            icon: Icon(Icons.access_time), label: Text('Attendance')),
        const NavigationRailDestination(
            icon: Icon(Icons.grade), label: Text('Grades')),
      ]);
      bottomNavItems.addAll([
        const BottomNavigationBarItem(
            icon: Icon(Icons.school), label: 'Students'),
        const BottomNavigationBarItem(
            icon: Icon(Icons.meeting_room), label: 'Classrooms'),
        const BottomNavigationBarItem(
            icon: Icon(Icons.access_time), label: 'Attendance'),
        const BottomNavigationBarItem(
            icon: Icon(Icons.grade), label: 'Grades'),
      ]);
      screens.addAll([
        StudentsScreen(apiService: apiService),
        ClassroomScreen(
          apiService: apiService,
          currentUserRole: 'TEACHER',
        ),
        AttendanceScreen(apiService: apiService, role: 'TEACHER'),
        GradesScreen(apiService: apiService),
      ]);
      titles.addAll(['Students', 'Classrooms', 'Attendance', 'Grades']);
    }

    // ADMIN
    if (userRoles.contains('ADMIN')) {
      railDestinations.addAll([
        const NavigationRailDestination(
            icon: Icon(Icons.person), label: Text('Teachers')),
        const NavigationRailDestination(
            icon: Icon(Icons.person), label: Text('Students')),
        const NavigationRailDestination(
            icon: Icon(Icons.book), label: Text('Subjects')),
        const NavigationRailDestination(
            icon: Icon(Icons.grade), label: Text('Grades')),
        const NavigationRailDestination(
            icon: Icon(Icons.meeting_room), label: Text('Classrooms')),
        const NavigationRailDestination(
            icon: Icon(Icons.access_time), label: Text('Attendance')),
        const NavigationRailDestination(
            icon: Icon(Icons.supervised_user_circle), label: Text('Users')),
      ]);

      bottomNavItems.addAll([
        const BottomNavigationBarItem(
            icon: Icon(Icons.person), label: 'Teachers'),
        const BottomNavigationBarItem(
            icon: Icon(Icons.person), label: 'Students'),
        const BottomNavigationBarItem(
            icon: Icon(Icons.book), label: 'Subjects'),
        const BottomNavigationBarItem(
            icon: Icon(Icons.grade), label: 'Grades'),
        const BottomNavigationBarItem(
            icon: Icon(Icons.meeting_room), label: 'Classrooms'),
        const BottomNavigationBarItem(
            icon: Icon(Icons.access_time), label: 'Attendance'),
        const BottomNavigationBarItem(
            icon: Icon(Icons.supervised_user_circle), label: 'Users'),
      ]);

      screens.addAll([
        TeachersScreen(apiService: apiService),
        StudentsScreen(apiService: apiService),
        SubjectScreen(apiService: apiService),
        GradesScreen(apiService: apiService),
        ClassroomScreen(
          apiService: apiService,
          currentUserRole: 'ADMIN',
        ),
        AttendanceScreen(apiService: apiService, role: 'ADMIN'),
        UserScreen(apiService: apiService, currentUserRole: 'ADMIN'),
      ]);

      titles.addAll(
          ['Teachers', 'Students', 'Subjects', 'Grades', 'Classrooms', 'Attendance', 'Users']);
    }

    final isSmallScreen = MediaQuery.of(context).size.width < 600;

    return Scaffold(
      appBar: AppBar(
        title: Text(titles[selectedIndex]),
        actions: [
          IconButton(onPressed: _logout, icon: const Icon(Icons.logout)),
        ],
      ),
      body: isSmallScreen
          ? screens[selectedIndex]
          : Row(
              children: [
                NavigationRail(
                  selectedIndex: selectedIndex,
                  onDestinationSelected: (index) =>
                      setState(() => selectedIndex = index),
                  labelType: NavigationRailLabelType.selected,
                  destinations: railDestinations,
                ),
                const VerticalDivider(thickness: 1, width: 1),
                Expanded(child: screens[selectedIndex]),
              ],
            ),
      bottomNavigationBar: isSmallScreen
          ? BottomNavigationBar(
              currentIndex: selectedIndex,
              onTap: (index) => setState(() => selectedIndex = index),
              items: bottomNavItems,
              type: BottomNavigationBarType.fixed,
            )
          : null,
    );
  }
}
