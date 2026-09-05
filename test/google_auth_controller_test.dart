import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
// ignore: depend_on_referenced_packages
import 'package:google_sign_in_platform_interface/google_sign_in_platform_interface.dart';
import 'package:neom_auth/ui/login/google_auth_controller.dart';
import 'package:neom_core/app_config.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'initializes once and absorbs normal Google cancellation events',
    () async {
      final originalPlatform = GoogleSignInPlatform.instance;
      final originalGuestMode = AppConfig.instance.isGuestMode;
      final fakePlatform = _FakeGoogleSignInPlatform();
      GoogleSignInPlatform.instance = fakePlatform;
      AppConfig.instance.isGuestMode = true;

      final controller = GoogleAuthController();
      addTearDown(() async {
        controller.onDelete();
        await fakePlatform.close();
        GoogleSignInPlatform.instance = originalPlatform;
        AppConfig.instance.isGuestMode = originalGuestMode;
      });

      final results = await Future.wait([
        controller.signIn(),
        controller.signIn(),
      ]);

      expect(results, everyElement(isFalse));
      expect(fakePlatform.initializationCount, 1);
      expect(fakePlatform.authenticationCount, 2);
      expect(fakePlatform.lightweightAuthenticationCount, 0);

      fakePlatform.emitCancellation();
      await Future<void>.delayed(Duration.zero);
    },
  );
}

class _FakeGoogleSignInPlatform extends GoogleSignInPlatform {
  final StreamController<AuthenticationEvent> _authenticationEvents =
      StreamController<AuthenticationEvent>.broadcast();

  int initializationCount = 0;
  int authenticationCount = 0;
  int lightweightAuthenticationCount = 0;

  @override
  Stream<AuthenticationEvent>? get authenticationEvents =>
      _authenticationEvents.stream;

  @override
  Future<void> init(InitParameters params) async {
    initializationCount++;
  }

  @override
  Future<AuthenticationResults?>? attemptLightweightAuthentication(
    AttemptLightweightAuthenticationParameters params,
  ) {
    lightweightAuthenticationCount++;
    return Future<AuthenticationResults?>.value();
  }

  @override
  bool supportsAuthenticate() => true;

  @override
  Future<AuthenticationResults> authenticate(
    AuthenticateParameters params,
  ) async {
    authenticationCount++;
    throw const GoogleSignInException(code: GoogleSignInExceptionCode.canceled);
  }

  @override
  bool authorizationRequiresUserInteraction() => false;

  @override
  Future<ClientAuthorizationTokenData?> clientAuthorizationTokensForScopes(
    ClientAuthorizationTokensForScopesParameters params,
  ) async => null;

  @override
  Future<ServerAuthorizationTokenData?> serverAuthorizationTokensForScopes(
    ServerAuthorizationTokensForScopesParameters params,
  ) async => null;

  @override
  Future<void> signOut(SignOutParams params) async {}

  @override
  Future<void> disconnect(DisconnectParams params) async {}

  void emitCancellation() {
    _authenticationEvents.add(
      const AuthenticationEventException(
        GoogleSignInException(code: GoogleSignInExceptionCode.canceled),
      ),
    );
  }

  Future<void> close() => _authenticationEvents.close();
}
