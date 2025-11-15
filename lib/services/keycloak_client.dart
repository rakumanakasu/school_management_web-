import 'package:oauth2_client/oauth2_client.dart';

class KeycloakClient extends OAuth2Client {
  KeycloakClient({
    required super.redirectUri,
    required super.customUriScheme,
    required String keycloakUrl,
    required String realm,
  }) : super(
          authorizeUrl:
              '$keycloakUrl/realms/$realm/protocol/openid-connect/auth',
          tokenUrl:
              '$keycloakUrl/realms/$realm/protocol/openid-connect/token',
        );
}
