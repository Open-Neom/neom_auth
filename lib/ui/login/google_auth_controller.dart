import 'package:google_sign_in/google_sign_in.dart';
import 'package:neom_core/app_config.dart';
import 'package:neom_core/cloud_properties.dart';
import 'package:neom_core/domain/use_cases/google_auth_service.dart';
import 'package:neom_core/utils/neom_error_logger.dart';
import 'package:neom_core/utils/platform/core_io.dart';
import 'package:flutter/foundation.dart';
import 'package:sint/sint.dart';

class GoogleAuthController extends SintController implements GoogleAuthService {
  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;
  GoogleSignInAccount? _currentUser;
  GoogleSignInAuthentication? _authCreds;

  @override
  void onInit() {
    super.onInit();
    AppConfig.logger.t("onInit GoogleAuthController (neom_auth)");
    _initializeGoogleSignIn();

    // Track current user changes via authenticationEvents stream
    _googleSignIn.authenticationEvents.listen((event) {
      if (event is GoogleSignInAuthenticationEventSignIn) {
        _currentUser = event.user;
        _authCreds = event.user.authentication;
      } else if (event is GoogleSignInAuthenticationEventSignOut) {
        _currentUser = null;
        _authCreds = null;
      }
      update();
    });

    // Try to silently sign in on startup to restore the session
    _googleSignIn.attemptLightweightAuthentication()?.then((account) {
      if (account != null) {
        _currentUser = account;
        _authCreds = account.authentication;
        AppConfig.logger.d("GoogleAuthController: Silently signed in as ${account.email}");
        update();
      }
    }).catchError((e) {
      AppConfig.logger.w("Failed silent Google Sign In: $e");
    });
  }

  void _initializeGoogleSignIn() {
    try {
      if (kIsWeb) {
        _googleSignIn.initialize(clientId: CloudProperties.getWebCliendId());
      } else if (Platform.isAndroid) {
        _googleSignIn.initialize(serverClientId: CloudProperties.getServerCliendId());
      } else if (Platform.isIOS) {
        _googleSignIn.initialize();
      } else if (Platform.isMacOS) {
        _googleSignIn.initialize(clientId: CloudProperties.getWebCliendId());
      }
    } catch (e, st) {
      AppConfig.logger.e("Failed to initialize Google Sign In: $e");
      NeomErrorLogger.recordError(e, st, module: 'neom_auth', operation: 'initializeGoogleSignIn');
    }
  }

  @override
  bool get isAuthenticated => _activeAccount != null;

  GoogleSignInAccount? get _activeAccount => _currentUser;

  @override
  String? get email => _activeAccount?.email;

  @override
  String? get displayName => _activeAccount?.displayName;

  @override
  String? get photoUrl => _activeAccount?.photoUrl;

  @override
  String? get idToken => _authCreds?.idToken;

  @override
  Future<bool> signIn({List<String>? scopes}) async {
    AppConfig.logger.d('GoogleAuthController (neom_auth): signIn...');
    try {
      GoogleSignInAccount? account = _activeAccount;

      if (account == null) {
        account = await _googleSignIn.authenticate(
          scopeHint: scopes ?? const <String>[],
        );
      }

      if (account == null) {
        AppConfig.logger.w('GoogleAuthController (neom_auth): no account selected');
        return false;
      }

      _currentUser = account;
      _authCreds = account.authentication;

      // Check and request incremental scopes if specified
      if (scopes != null && scopes.isNotEmpty) {
        var authz = await account.authorizationClient.authorizationForScopes(scopes);
        if (authz == null) {
          AppConfig.logger.d('GoogleAuthController (neom_auth): requesting scopes: $scopes');
          authz = await account.authorizationClient.authorizeScopes(scopes);
        }
        if (authz == null) {
          AppConfig.logger.e('GoogleAuthController (neom_auth): failed to authorize scopes');
          return false;
        }
      }

      update();
      return true;
    } catch (e, st) {
      NeomErrorLogger.recordError(e, st, module: 'neom_auth', operation: 'signIn');
      return false;
    }
  }

  @override
  Future<void> signOut() async {
    AppConfig.logger.d('GoogleAuthController (neom_auth): signOut...');
    try {
      await _googleSignIn.signOut();
      _currentUser = null;
      _authCreds = null;
      update();
    } catch (e, st) {
      NeomErrorLogger.recordError(e, st, module: 'neom_auth', operation: 'signOut');
    }
  }

  @override
  Future<bool> refreshToken({List<String>? scopes}) async {
    AppConfig.logger.d('GoogleAuthController (neom_auth): refreshToken...');
    try {
      final account = await _googleSignIn.attemptLightweightAuthentication();
      if (account == null) return false;

      _currentUser = account;
      _authCreds = account.authentication;
      update();
      return true;
    } catch (e, st) {
      NeomErrorLogger.recordError(e, st, module: 'neom_auth', operation: 'refreshToken');
      return false;
    }
  }

  @override
  Future<String?> getValidAccessToken({List<String>? scopes, bool forceRefresh = false}) async {
    try {
      GoogleSignInAccount? account = _activeAccount;

      if (account == null && forceRefresh) {
        final success = await signIn(scopes: scopes);
        if (success) {
          account = _activeAccount;
        }
      }

      if (account == null) return null;

      // Request or check authorization for the scopes using authorizationClient
      final List<String> targetScopes = scopes ?? const <String>['email', 'profile'];
      var authz = await account.authorizationClient.authorizationForScopes(targetScopes);
      if (authz == null && forceRefresh) {
        authz = await account.authorizationClient.authorizeScopes(targetScopes);
      }
      return authz?.accessToken;
    } catch (e, st) {
      NeomErrorLogger.recordError(e, st, module: 'neom_auth', operation: 'getValidAccessToken');
      return null;
    }
  }
}

