import 'package:flutter_test/flutter_test.dart';
import 'package:school_management_frontend/main.dart';
import 'package:school_management_frontend/services/auth_service.dart';

void main() {
  testWidgets('App loads and shows login or home', (WidgetTester tester) async {
    // Create dummy AuthService instance
    final authService = await AuthService.getInstance();

    // Build the app with isLoggedIn = false
    await tester.pumpWidget(MyApp(authService: authService, isLoggedIn: false));

    // Expect to see login screen
    expect(find.text('Login'), findsWidgets); // Adjust based on your login screen UI
  });
}
