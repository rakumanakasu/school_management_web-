// lib/config/config.dart

class AppConfig {
  // Keycloak
  static const keycloakUrl = String.fromEnvironment(
      'KEYCLOAK_URL',
      defaultValue: 'http://localhost:8067'); // fallback for dev
  static const keycloakRealm = 'su79-school-management-realm';
  static const keycloakClientId = 'school-management-client';
  static const keycloakClientSecret =
      'QW8fdPs3f7jMVyZs9BtwdBJjlx6JcQ8d'; // confidential

  // Backend API
  static const apiUrl = String.fromEnvironment(
      'API_URL',
      defaultValue: 'http://localhost:8081'); // fallback for dev
}
