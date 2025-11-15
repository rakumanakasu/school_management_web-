import 'dart:ui';

import 'package:flutter_flavor/flutter_flavor.dart';

void setupFlavors() {
  FlavorConfig(
    name: "DEV",
    color: const Color(0xFF2196F3),
    variables: {
      "API_BASE_URL": "http://localhost:8081/api/v1",
      "KEYCLOAK_URL": "http://localhost:8069",
      "REALM": "su7.9-school-management-reaalm",
      "CLIENT_ID": "school-management-client",
      "REDIRECT_URI": "http://localhost:56222/",
    },
  );
}
