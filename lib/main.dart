import 'package:flutter/material.dart';
import 'package:school_management_frontend/screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'services/auth_service.dart';
import 'services/session_storage_service.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:device_preview/device_preview.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final authService = await AuthService.getInstance();
  final storage = await SessionStorageService.getInstance();
  final token = storage.retrieveAccessToken();
  final bool isLoggedIn = token != null && !JwtDecoder.isExpired(token);

  runApp(
    DevicePreview(
      enabled: true, // turn ON phone preview
      builder: (context) => MyApp(
        authService: authService,
        isLoggedIn: isLoggedIn,
      ),
    ),
  );
}

class MyApp extends StatelessWidget {
  final AuthService authService;
  final bool isLoggedIn;

  const MyApp({
    super.key,
    required this.authService,
    required this.isLoggedIn,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'School Management',

      // Required for DevicePreview to work
      builder: DevicePreview.appBuilder,
      useInheritedMediaQuery: true,
      locale: DevicePreview.locale(context),

      theme: ThemeData(primarySwatch: Colors.blue),

      home: isLoggedIn
          ? const HomePage()
          : LoginScreen(authService: authService),
    );
  }
}
