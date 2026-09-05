import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:neom_core/app_config.dart';
import 'package:neom_core/cloud_properties.dart';
import 'package:neom_core/domain/use_cases/google_auth_service.dart';
import 'package:neom_core/utils/neom_error_logger.dart';
import 'package:neom_core/utils/platform/core_io.dart';
import 'package:sint/sint.dart';

class GoogleAuthController extends SintController implements GoogleAuthService {
  static Future<void>? _googleSignInInitialization;

  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;
  StreamSubscription<GoogleSignInAuthenticationEvent>?
  _authenticationEventsSubscription;
  Future<void>? _ready;

  GoogleSignInAccount? _currentUser;
  GoogleSignInAuthentication? _authCreds;

  @override
  void onInit() {
    super.onInit();
    AppConfig.logger.t("onInit GoogleAuthController (neom_auth)");
  }

  Future<void> _ensureReady() {
    return _ready ??= _initializeAndSubscribe();
  }

  Future<void> _initializeAndSubscribe() async {
    await (_googleSignInInitialization ??= _initializeGoogleSignIn(
      _googleSignIn,
    ));

    if (isClosed) return;

    _authenticationEventsSubscription ??= _googleSignIn.authenticationEvents
        .listen(
          _handleAuthenticationEvent,
          onError: _handleAuthenticationError,
        );
  }

  static Future<void> _initializeGoogleSignIn(GoogleSignIn googleSignIn) async {
    if (kIsWeb) {
      await googleSignIn.initialize(clientId: CloudProperties.getWebCliendId());
    } else if (Platform.isAndroid) {
      await googleSignIn.initialize(
        serverClientId: CloudProperties.getServerCliendId(),
      );
    } else {
      await googleSignIn.initialize();
    }
  }

  void _handleAuthenticationEvent(GoogleSignInAuthenticationEvent event) {
    if (event is GoogleSignInAuthenticationEventSignIn) {
      _setCurrentUser(event.user);
    } else if (event is GoogleSignInAuthenticationEventSignOut) {
      _clearCurrentUser();
    }
    update();
  }

  void _handleAuthenticationError(Object error, StackTrace stackTrace) {
    if (error is GoogleSignInException && _isExpectedCancellation(error)) {
      AppConfig.logger.d(
        'GoogleAuthController: Google authentication cancelled.',
      );
      return;
    }

    AppConfig.logger.w(
      'GoogleAuthController: authentication event failed: $error',
    );
    NeomErrorLogger.recordError(
      error,
      stackTrace,
      module: 'neom_auth',
      operation: 'googleAuthenticationEvent',
    );
  }

  void _setCurrentUser(GoogleSignInAccount account) {
    _currentUser = account;
    _authCreds = account.authentication;
  }

  void _clearCurrentUser() {
    _currentUser = null;
    _authCreds = null;
  }

  bool get _canRestoreMobileSession =>
      !kIsWeb &&
      !AppConfig.instance.isGuestMode &&
      (Platform.isAndroid || Platform.isIOS || Platform.isMacOS);

  Future<GoogleSignInAccount?> _restoreMobileSession() async {
    if (!_canRestoreMobileSession) return null;

    try {
      final authentication = _googleSignIn.attemptLightweightAuthentication();
      final account = authentication == null ? null : await authentication;
      if (account != null) {
        _setCurrentUser(account);
        AppConfig.logger.d(
          'GoogleAuthController: restored Google session for ${account.email}',
        );
        update();
      }
      return account;
    } on GoogleSignInException catch (e, st) {
      if (_isExpectedCancellation(e)) return null;
      NeomErrorLogger.recordError(
        e,
        st,
        module: 'neom_auth',
        operation: 'restoreGoogleSession',
      );
      return null;
    } catch (e, st) {
      NeomErrorLogger.recordError(
        e,
        st,
        module: 'neom_auth',
        operation: 'restoreGoogleSession',
      );
      return null;
    }
  }

  static bool _isExpectedCancellation(GoogleSignInException exception) {
    switch (exception.code) {
      case GoogleSignInExceptionCode.canceled:
      case GoogleSignInExceptionCode.interrupted:
      case GoogleSignInExceptionCode.uiUnavailable:
        return true;
      default:
        return false;
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
      await _ensureReady();

      GoogleSignInAccount? account = _activeAccount;
      account ??= await _restoreMobileSession();

      if (account == null) {
        try {
          await _googleSignIn.signOut();
        } catch (_) {}
        account = await _googleSignIn.authenticate(
          scopeHint: scopes ?? const <String>[],
        );
      }

      _setCurrentUser(account);

      // Check and request incremental scopes if specified
      if (scopes != null && scopes.isNotEmpty) {
        var authz = await account.authorizationClient.authorizationForScopes(
          scopes,
        );
        if (authz == null) {
          AppConfig.logger.d(
            'GoogleAuthController (neom_auth): requesting scopes: $scopes',
          );
          await account.authorizationClient.authorizeScopes(scopes);
        }
      }

      update();
      return true;
    } on GoogleSignInException catch (e, st) {
      if (_isExpectedCancellation(e)) {
        AppConfig.logger.d(
          'GoogleAuthController: interactive Google sign-in cancelled.',
        );
        return false;
      }
      NeomErrorLogger.recordError(
        e,
        st,
        module: 'neom_auth',
        operation: 'signIn',
      );
      return false;
    } catch (e, st) {
      NeomErrorLogger.recordError(
        e,
        st,
        module: 'neom_auth',
        operation: 'signIn',
      );
      return false;
    }
  }

  @override
  Future<void> signOut() async {
    AppConfig.logger.d('GoogleAuthController (neom_auth): signOut...');
    try {
      await _ensureReady();
      await _googleSignIn.signOut();
      _clearCurrentUser();
      update();
    } catch (e, st) {
      NeomErrorLogger.recordError(
        e,
        st,
        module: 'neom_auth',
        operation: 'signOut',
      );
    }
  }

  @override
  Future<bool> refreshToken({List<String>? scopes}) async {
    AppConfig.logger.d('GoogleAuthController (neom_auth): refreshToken...');

    // On web this method can invoke FedCM/One Tap UI without a user gesture.
    // Guests must also remain free of implicit auth prompts.
    if (kIsWeb || AppConfig.instance.isGuestMode) return false;

    try {
      await _ensureReady();
      final account = await _restoreMobileSession();
      if (account == null) return false;

      _setCurrentUser(account);
      update();
      return true;
    } on GoogleSignInException catch (e, st) {
      if (_isExpectedCancellation(e)) return false;
      NeomErrorLogger.recordError(
        e,
        st,
        module: 'neom_auth',
        operation: 'refreshToken',
      );
      return false;
    } catch (e, st) {
      NeomErrorLogger.recordError(
        e,
        st,
        module: 'neom_auth',
        operation: 'refreshToken',
      );
      return false;
    }
  }

  @override
  Future<String?> getValidAccessToken({
    List<String>? scopes,
    bool forceRefresh = false,
  }) async {
    try {
      await _ensureReady();

      GoogleSignInAccount? account = _activeAccount;
      account ??= await _restoreMobileSession();

      if (account == null && forceRefresh) {
        final success = await signIn(scopes: scopes);
        if (success) {
          account = _activeAccount;
        }
      }

      if (account == null) return null;

      // Request or check authorization for the scopes using authorizationClient
      final List<String> targetScopes =
          scopes ?? const <String>['email', 'profile'];
      var authz = await account.authorizationClient.authorizationForScopes(
        targetScopes,
      );
      if (authz == null && forceRefresh) {
        authz = await account.authorizationClient.authorizeScopes(targetScopes);
      }
      return authz?.accessToken;
    } catch (e, st) {
      NeomErrorLogger.recordError(
        e,
        st,
        module: 'neom_auth',
        operation: 'getValidAccessToken',
      );
      return null;
    }
  }

  @override
  void onClose() {
    final subscription = _authenticationEventsSubscription;
    _authenticationEventsSubscription = null;
    if (subscription != null) {
      unawaited(subscription.cancel());
    }
    super.onClose();
  }
}
