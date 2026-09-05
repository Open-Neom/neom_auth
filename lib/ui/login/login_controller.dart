import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart' as fba;
import 'package:neom_core/utils/platform/core_io.dart';
import 'package:neom_core/data/firestore/profile_document_locator.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:sint/sint.dart';
import 'package:neom_core/domain/use_cases/google_auth_service.dart';
import 'package:neom_commons/utils/app_utilities.dart';
import 'package:neom_commons/utils/constants/translations/message_translation_constants.dart';
import 'package:neom_commons/utils/device_utilities.dart';
import 'package:neom_commons/utils/security_utilities.dart';
import 'package:neom_commons/utils/auth_guard.dart';
import 'package:neom_core/app_config.dart';
import 'package:neom_core/utils/enums/app_in_use.dart';
import 'package:neom_core/utils/neom_error_logger.dart';
import 'package:neom_core/utils/neom_flow_tracker.dart';
import 'package:neom_core/cloud_properties.dart';
import 'package:neom_core/data/firestore/constants/app_firestore_constants.dart';
import 'package:neom_core/data/firestore/profile_firestore.dart';
import 'package:neom_core/data/implementations/app_hive_controller.dart';
import 'package:neom_core/domain/model/app_profile.dart';
import 'package:neom_core/domain/model/app_user.dart';
import 'package:neom_core/domain/use_cases/audio_handler_service.dart';
import 'package:neom_core/domain/use_cases/login_service.dart';
import 'package:neom_core/domain/use_cases/user_service.dart';
import 'package:neom_core/utils/constants/app_route_constants.dart';
import 'package:neom_core/utils/enums/auth_status.dart';
import 'package:neom_core/utils/enums/signed_in_with.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import '../../utils/constants/auth_translation_constants.dart';
import '../../utils/enums/login_method.dart';

class LoginController extends SintController implements LoginService {

  static const Set<String> _webOAuthCancellationCodes = {
    'popup-closed-by-user',
    'cancelled-popup-request',
    'canceled-popup-request',
    'redirect-cancelled-by-user',
    'redirect-canceled-by-user',
    'web-context-canceled',
    'user-cancelled',
    'user-canceled',
  };

  static const Set<String> _webOAuthRedirectFallbackCodes = {
    'popup-blocked',
    'operation-not-supported-in-this-environment',
    'web-storage-unsupported',
  };

  final userServiceImpl = Sint.find<UserService>();

  TextEditingController _emailController = TextEditingController();
  TextEditingController _passwordController = TextEditingController();

  FocusNode _emailFocusNode = FocusNode();
  FocusNode _passwordFocusNode = FocusNode();

  TextEditingController get emailController {
    try {
      final _ = _emailController.text;
    } catch (_) {
      _emailController = TextEditingController();
    }
    return _emailController;
  }

  TextEditingController get passwordController {
    try {
      final _ = _passwordController.text;
    } catch (_) {
      _passwordController = TextEditingController();
    }
    return _passwordController;
  }

  FocusNode get emailFocusNode {
    try {
      final _ = _emailFocusNode.hasFocus;
    } catch (_) {
      _emailFocusNode = FocusNode();
    }
    return _emailFocusNode;
  }

  FocusNode get passwordFocusNode {
    try {
      final _ = _passwordFocusNode.hasFocus;
    } catch (_) {
      _passwordFocusNode = FocusNode();
    }
    return _passwordFocusNode;
  }
  Rx<AuthStatus> authStatus = AuthStatus.waiting.obs;

  String _userId = "";
  final String _fbAccessToken = "";
  fba.AuthCredential? credentials;

  fba.FirebaseAuth _auth = fba.FirebaseAuth.instance;
  final Rxn<fba.User> _fbaUser = Rxn<fba.User>();
  StreamSubscription<fba.User?>? _authStateChangesSubscription;
  StreamSubscription<fba.User?>? _fbaUserSubscription;

  SignedInWith _signedInWith = SignedInWith.notDetermined;
  LoginMethod loginMethod = LoginMethod.notDetermined;
  
  final RxBool isLoading = true.obs;
  final RxBool isButtonDisabled = false.obs;

  bool isPhoneAuth = false;
  String phoneVerificationId = '';

  bool isAppleSignInAvailable = false;
  bool _isProcessingAuth = false;

  @override
  void onInit() {
    super.onInit();
    AppConfig.logger.t("onInit Login Controller");
    _authStateChangesSubscription = _auth.authStateChanges().listen((user) {
      _fbaUser.value = user;
      handleAuthChanged(user);
    });
    _fbaUserSubscription = _fbaUser.listen(handleAuthChanged);

    if(kIsWeb) {
      isAppleSignInAvailable = true;
      _checkRedirectResult();
    } else if(Platform.isAndroid) {
      AppConfig.logger.t(Platform.version);
    } else if(Platform.isIOS) {
      isAppleSignInAvailable = DeviceUtilities.isDeviceSupportedVersion(isIOS: Platform.isIOS);
    } else if(Platform.isMacOS) {
      isAppleSignInAvailable = true;
    }

  }

  @override
  void onReady() {
    super.onReady();
    AppConfig.logger.t("onReady Login Controller");
    isLoading.value = false;

    // Fallback: If authStatus is still waiting after 1.2s, resolve initial auth state
    Future.delayed(const Duration(milliseconds: 1200), () {
      if (authStatus.value == AuthStatus.waiting) {
        AppConfig.logger.i("AuthStatus fallback: resolving initial auth state from currentUser");
        handleAuthChanged(_auth.currentUser);
      }
    });
  }

  @override
  void onClose() {
    // NOTE: Do NOT dispose TextEditingControllers/FocusNodes nor cancel the
    // auth subscriptions here. This controller is registered as
    // `permanent: true` in every host app's RootBinding (Gigmeout, Emxi,
    // Cyberneom), but Sint still calls onClose during navigation
    // (offAllNamed) — while the SAME instance keeps being served. Disposing
    // resources here leaves the login page broken with
    // "FocusNode was used after being disposed" on the next visit.
    // The controllers are garbage collected when the controller itself is
    // disposed at app shutdown.
    super.onClose();
  }

  /// Checks for pending OAuth redirect results (used by Safari fallback).
  /// When signInWithPopup fails (Safari ITP blocks popups), we fall back to
  /// signInWithRedirect. On page reload, this picks up the redirect result.
  Future<void> _checkRedirectResult() async {
    try {
      final result = await _auth.getRedirectResult();
      if (result.user != null) {
        AppConfig.logger.i('OAuth redirect result received for: ${result.user?.email}');
        _fbaUser.value = result.user;
        authStatus.value = AuthStatus.loggedIn;

        // Determine sign-in provider
        final providerId = result.credential?.providerId ?? '';
        if (providerId.contains('google')) {
          signedInWith = SignedInWith.google;
        } else if (providerId.contains('apple')) {
          signedInWith = SignedInWith.apple;
        }
      }
    } on fba.FirebaseAuthException catch (e, st) {
      if (_isWebOAuthCancellation(e)) {
        AppConfig.logger.d('OAuth redirect was cancelled by the user.');
        return;
      }
      NeomErrorLogger.recordError(e, st, module: 'neom_auth', operation: '_checkRedirectResult');
    } catch (e, st) {
      NeomErrorLogger.recordError(e, st, module: 'neom_auth', operation: '_checkRedirectResult');
    }
  }

  static String _normalizedFirebaseAuthCode(String code) {
    return code.startsWith('auth/') ? code.substring(5) : code;
  }

  static bool _isWebOAuthCancellation(fba.FirebaseAuthException exception) {
    return _webOAuthCancellationCodes.contains(
      _normalizedFirebaseAuthCode(exception.code),
    );
  }

  static bool _shouldFallbackToWebOAuthRedirect(
    fba.FirebaseAuthException exception,
  ) {
    return _webOAuthRedirectFallbackCodes.contains(
      _normalizedFirebaseAuthCode(exception.code),
    );
  }

  @override
  Future<void> handleAuthChanged(fba.User? user) async {

    // Si ya estamos procesando un cambio de auth, ignoramos los disparos duplicados
    if (_isProcessingAuth) {
      AppConfig.logger.d("handleAuthChanged ignorado: ya se está procesando uno.");
      return;
    }
    _isProcessingAuth = true; // Bloqueamos
    AppConfig.logger.d("handleAuthChanged - Procesando para user: ${user?.uid}");
    NeomFlowTracker.startFlow('login');
    authStatus.value = AuthStatus.waiting;

    try {
      if(isPhoneAuth) return;
      if(_auth.currentUser == null) {
        authStatus.value = AuthStatus.notLoggedIn;
        _auth = fba.FirebaseAuth.instance;
      } else if(user == null && _auth.currentUser != null) {
        authStatus.value = AuthStatus.notLoggedIn;
        user = _auth.currentUser!;
      } else if(user != null) {
        if(user.providerData.isNotEmpty) {
          // Priorizar email sobre providerData.uid ya que los userId modernos son emails
          String? email = user.providerData.first.email ?? user.email;
          if(email?.isNotEmpty ?? false) {
            _userId = email!;
            await userServiceImpl.setUserByEmail(email);
          } else {
            _userId = user.providerData.first.uid!;
            await userServiceImpl.setUserById(_userId);
          }
        }

        if(userServiceImpl.user.id.isEmpty) {
          AppConfig.logger.d("User not found in Firestore for $_userId.");
          switch(signedInWith) {
            case(SignedInWith.signUp):
              gotoIntroPage();
              break;
            case(SignedInWith.email):
            case(SignedInWith.google):
            case(SignedInWith.apple):
              userServiceImpl.getUserFromFirebase(user);
              break;
            case(SignedInWith.facebook):
            case(SignedInWith.spotify):
              break;
            case(SignedInWith.notDetermined):
              authStatus.value = AuthStatus.notLoggedIn;
              break;
          }
        } else if(!userServiceImpl.isNewUser && userServiceImpl.user.profiles.isEmpty) {
          AppConfig.logger.i("No Profiles found for $_userId. Please Login Again");
          authStatus.value = AuthStatus.notLoggedIn;
        } else {
          authStatus.value = AuthStatus.loggedIn;
          AppConfig.instance.isGuestMode = false;
          // Sync Google Auth photo and name to profile if profile fields are empty
          if (user.displayName?.isNotEmpty == true && userServiceImpl.profile.name.isEmpty) {
            userServiceImpl.profile.name = user.displayName!;
            if (userServiceImpl.profile.id.isNotEmpty) {
              ProfileFirestore().updateName(userServiceImpl.profile.id, user.displayName!);
            }
          }
          if (user.photoURL?.isNotEmpty == true && userServiceImpl.profile.photoUrl.isEmpty) {
            userServiceImpl.profile.photoUrl = user.photoURL!;
            if (userServiceImpl.profile.id.isNotEmpty) {
              ProfileFirestore().updatePhotoUrl(userServiceImpl.profile.id, user.photoURL!);
            }
          }
          await Sint.find<AppHiveController>().writeProfileInfo();
        }

        if(userServiceImpl.isNewUser && userServiceImpl.user.id.isNotEmpty) {
          NeomFlowTracker.endFlow('login');
          NeomFlowTracker.startFlow('registration');
          gotoIntroPage();
        } else if (authStatus.value == AuthStatus.loggedIn) {
          NeomFlowTracker.setUserId(userServiceImpl.user.id);
          NeomFlowTracker.endFlow('login');
          // Check if redirected from a protected route
          if (Sint.arguments != null && Sint.arguments['nextRoute'] != null) {
            String nextRoute = Sint.arguments['nextRoute'];
            dynamic nextArgs = Sint.arguments['nextArgs'];
            AppConfig.logger.i("Redirecting to nextRoute after login success: $nextRoute");
            Sint.offAllNamed(nextRoute, arguments: nextArgs);
          } else if (AuthGuard.pendingRedirectRoute != null) {
            final nextRoute = AuthGuard.pendingRedirectRoute!;
            final nextArgs = AuthGuard.pendingRedirectArgs;
            AuthGuard.pendingRedirectRoute = null;
            AuthGuard.pendingRedirectArgs = null;
            AppConfig.logger.i("Redirecting to pending nextRoute: $nextRoute");
            Sint.offAllNamed(nextRoute, arguments: nextArgs);
          } else {
            final currentRoute = Sint.currentRoute;
            if (currentRoute == AppRouteConstants.login) {
              AppConfig.logger.i("User found for $_userId. Navigating to Root Page from Login Page");
              Sint.offAllNamed(AppRouteConstants.root);
            } else if (currentRoute.isEmpty || currentRoute == AppRouteConstants.root) {
              AppConfig.logger.i("User found for $_userId on root entry point. Updating reactive root state");
            } else {
              AppConfig.logger.i("User found for $_userId. Preserving deep-link route: $currentRoute");
            }
          }
        }
      }
    } catch (e, st) {
      NeomFlowTracker.endFlow('login', success: false);
      NeomErrorLogger.recordError(e, st, module: 'neom_auth', operation: 'handleAuthChanged');
      AppUtilities.showSnackBar(
        title: MessageTranslationConstants.errorHandlingAuth,
        message: e.toString()
      );
      Sint.offAllNamed(AppRouteConstants.root);
    } finally {
      isLoading.value = false;
      _isProcessingAuth = false; // LIBERAMOS el semáforo
      update();
    }

    update();
  }

  void gotoIntroPage() {
    AppConfig.logger.i("New User found for $_userId. Redirecting to Intro Page");
    authStatus.value = AuthStatus.loggedIn;

    // SAIA OAuth: skip full onboarding, create account directly
    if (AppConfig.instance.appInUse == AppInUse.i
        && (signedInWith == SignedInWith.google || signedInWith == SignedInWith.apple)) {
      AppConfig.logger.i("SAIA OAuth detected (signedInWith: $signedInWith). Skipping onboarding.");
      _quickCreateSaiaAccount();
      return;
    }

    Sint.toNamed(AppRouteConstants.introRequiredPermissions);
  }

  /// Fast-track account creation for SAIA OAuth sign-ins.
  /// Uses OAuth profile data (name, photo) and skips onboarding wizard.
  Future<void> _quickCreateSaiaAccount() async {
    try {
      AppConfig.logger.i("SAIA OAuth quick-create for $_userId");
      await userServiceImpl.createUser();
      NeomFlowTracker.endFlow('registration');
      
      if (AuthGuard.pendingRedirectRoute != null) {
        final nextRoute = AuthGuard.pendingRedirectRoute!;
        final nextArgs = AuthGuard.pendingRedirectArgs;
        AuthGuard.pendingRedirectRoute = null;
        AuthGuard.pendingRedirectArgs = null;
        AppConfig.logger.i("Redirecting to pending nextRoute after SAIA quick-signup: $nextRoute");
        Sint.offAllNamed(nextRoute, arguments: nextArgs);
      } else {
        Sint.offAllNamed(AppRouteConstants.home);
      }
    } catch (e, st) {
      AppConfig.logger.e("SAIA quick create failed: $e");
      NeomErrorLogger.recordError(e, st, module: 'neom_auth', operation: 'quickCreateSaia');
      // Fallback to normal onboarding
      Sint.toNamed(AppRouteConstants.introRequiredPermissions);
    }
  }

  Future<void> handleLogin(LoginMethod logMethod) async {

    isButtonDisabled.value = true;
    isLoading.value = true;
    loginMethod = logMethod;

    try {
      switch (loginMethod) {
        case LoginMethod.email:
          await emailLogin();
          break;
        case LoginMethod.google:
          await googleLogin();
          break;
        case LoginMethod.apple:
          await appleLogin();
          break;
        case LoginMethod.facebook:
          break;
        case LoginMethod.spotify:
          break;
        case LoginMethod.notDetermined:
          break;
      }
    } catch (e, st) {
      NeomErrorLogger.recordError(e, st, module: 'neom_auth', operation: 'handleLogin');
      isLoading.value = false;
    }
    isButtonDisabled.value = false;
  }

  @override
  Future<void> emailLogin() async {

    fba.User? emailUser;
    try {
      fba.UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim()
      );

       if(userCredential.user != null) {
         emailUser = userCredential.user;
         _fbaUser.value = emailUser;
         authStatus.value = AuthStatus.loggedIn;
         signedInWith = SignedInWith.email;
       }
    } on fba.FirebaseAuthException catch (e, st) {
      NeomErrorLogger.recordError(e, st, module: 'neom_auth', operation: 'emailLogin');

      String errorMsg = "";
      switch (e.code) {
        case AppFirestoreConstants.wrongPassword:
          errorMsg = MessageTranslationConstants.invalidPassword;
          break;
        case AppFirestoreConstants.invalidEmail:
          errorMsg = MessageTranslationConstants.invalidEmailFormat;
          break;
        case AppFirestoreConstants.userNotFound:
          errorMsg = MessageTranslationConstants.userNotFound;
          break;
        case AppFirestoreConstants.unknown:
          errorMsg = MessageTranslationConstants.pleaseFillSignUpForm;
          break;

      }

      AppUtilities.showSnackBar(
          title: MessageTranslationConstants.errorLoginEmail.tr,
          message: errorMsg.tr
      );
    } catch (e, st) {
      NeomErrorLogger.recordError(e, st, module: 'neom_auth', operation: 'emailLogin');
      AppUtilities.showSnackBar(
          title: MessageTranslationConstants.errorLoginEmail.tr,
          message: e.toString(),
      );
    } finally {
      isButtonDisabled.value = false;
      if(emailUser == null) {
        isLoading.value = false;
      }
    }

  }

  @override
  Future<void> appleLogin() async {
    AppConfig.logger.d("Entering Logging Method with Apple Account");

    try {
      if (kIsWeb) {
        // Web: try signInWithPopup first, fallback to signInWithRedirect for Safari.
        final appleProvider = fba.OAuthProvider('apple.com');
        appleProvider.addScope('email');
        appleProvider.addScope('name');
        try {
          AppConfig.logger.i('Web: trying signInWithPopup for Apple');
          final result = await _auth.signInWithPopup(appleProvider);
          if (result.user != null) {
            _fbaUser.value = result.user;
            authStatus.value = AuthStatus.loggedIn;
            signedInWith = SignedInWith.apple;
          }
        } catch (popupError) {
          AppConfig.logger.w('signInWithPopup failed for Apple, falling back to signInWithRedirect: $popupError');
          await _auth.signInWithRedirect(appleProvider);
        }
      } else {
        await setAuthCredentials();

        if(credentials != null) {
          fba.UserCredential userCredential = await _auth.signInWithCredential(credentials!);
          _fbaUser.value = userCredential.user;
          authStatus.value = AuthStatus.loggedIn;
          signedInWith = SignedInWith.apple;
        }
      }

    } on SignInWithAppleAuthorizationException catch (e, st) {

      NeomErrorLogger.recordError(e, st, module: 'neom_auth', operation: 'appleLogin');
      _fbaUser.value = null;
      authStatus.value = AuthStatus.notLoggedIn;

      if(e.code != AuthorizationErrorCode.canceled) {
        AppUtilities.showSnackBar(
          title: MessageTranslationConstants.errorLoginApple.tr,
          message: MessageTranslationConstants.errorLoginApple.tr,
        );
      }

    } catch (e, st) {
      _fbaUser.value = null;
      authStatus.value = AuthStatus.notLoggedIn;
      NeomErrorLogger.recordError(e, st, module: 'neom_auth', operation: 'appleLogin');

      AppUtilities.showSnackBar(
        title: MessageTranslationConstants.errorLoginApple.tr,
        message: MessageTranslationConstants.errorLoginApple.tr,
      );
    } finally {
      isButtonDisabled.value = false;
      isLoading.value = false;
    }

  }

  @override
  Future<void> googleLogin() async {

    AppConfig.logger.i("Entering Logging Method with Google Account");

    try {
      if (kIsWeb) {
        // Web: try signInWithPopup first (works in Chrome, Edge, Firefox).
        // Falls back to signInWithRedirect for Safari (ITP blocks popups).
        final googleProvider = fba.GoogleAuthProvider();
        try {
          AppConfig.logger.i('Web: trying signInWithPopup for Google');
          final result = await _auth.signInWithPopup(googleProvider);
          if (result.user != null) {
            _fbaUser.value = result.user;
            authStatus.value = AuthStatus.loggedIn;
            signedInWith = SignedInWith.google;
          }
        } on fba.FirebaseAuthException catch (popupError) {
          if (_isWebOAuthCancellation(popupError)) {
            AppConfig.logger.d('Google popup was cancelled by the user.');
            return;
          }
          if (!_shouldFallbackToWebOAuthRedirect(popupError)) {
            rethrow;
          }

          AppConfig.logger.w(
            'Google popup unavailable; falling back to redirect: '
            '${popupError.code}',
          );
          await _auth.signInWithRedirect(googleProvider);
          // Page will reload — getRedirectResult() in onInit handles the result
        }
      } else {
        await setAuthCredentials();

        if(credentials != null) {
          _fbaUser.value = (await _auth.signInWithCredential(credentials!)).user;
          authStatus.value = AuthStatus.loggedIn;
          signedInWith = SignedInWith.google;
        }
      }
    } on fba.FirebaseAuthException catch (e, st) {
      if (_isWebOAuthCancellation(e)) {
        AppConfig.logger.d('Google login was cancelled by the user.');
        return;
      }

      _fbaUser.value = null;
      authStatus.value = AuthStatus.notLoggedIn;
      NeomErrorLogger.recordError(e, st, module: 'neom_auth', operation: 'googleLogin');

      AppUtilities.showSnackBar(
        title: MessageTranslationConstants.errorLoginGoogle.tr,
        message: MessageTranslationConstants.errorLoginGoogle.tr,
      );
    } catch (e, st) {
      _fbaUser.value = null;
      authStatus.value = AuthStatus.notLoggedIn;
      NeomErrorLogger.recordError(e, st, module: 'neom_auth', operation: 'googleLogin');

      AppUtilities.showSnackBar(
        title: MessageTranslationConstants.errorLoginGoogle.tr,
        message: MessageTranslationConstants.errorLoginGoogle.tr,
      );
    } finally {
      if(credentials == null) isLoading.value = false;
    }
  }

  //TODO To Verify Implementation
  Future<void> googleLogout() async {
    // Firebase Auth owns the web Google session. Initializing google_sign_in
    // here would unnecessarily start the separate GSI/FedCM stack on logout.
    if (kIsWeb || !Sint.isRegistered<GoogleAuthService>()) return;

    try {
      await Sint.find<GoogleAuthService>().signOut();
    } catch (e, st){
      NeomErrorLogger.recordError(e, st, module: 'neom_auth', operation: 'googleLogout');
    }
  }

  @override
  Future<void> signOut() async {
    AppConfig.logger.d("Entering signOut method");
    try {
      await _auth.signOut();
      await googleLogout();
      clear();
      userServiceImpl.user = AppUser();
      userServiceImpl.profile = AppProfile();
      AppConfig.instance
        ..authStatus = AuthStatus.notLoggedIn
        ..isGuestMode = true;
      // Profile document paths are memoized per process; a new session must not
      // inherit the previous user's resolved references.
      ProfileDocumentLocator().clear();
      if(Sint.isRegistered<AudioHandlerService>()) {
        AudioHandlerService audioHandler = Sint.find<AudioHandlerService>();
        if(audioHandler.isPlaying) {
          audioHandler.stop();
        }
      }
      Sint.offAllNamed(AppRouteConstants.login);
    } catch (e) {
      AppUtilities.showSnackBar(
        title: MessageTranslationConstants.errorSigningOut.tr,
        message: e.toString(),
      );
    }

    AppConfig.logger.i("signOut method finished");
  }


  @override
  Future<void> sendEmailVerification(GlobalKey<ScaffoldState> scaffoldKey) {
    throw UnimplementedError();
  }


  void clear() {
    _fbaUser.value = null;
    authStatus.value = AuthStatus.notLoggedIn;
    isButtonDisabled.value = false;

    // SECURITY: Clear sensitive data from text controllers on logout
    emailController.clear();
    passwordController.clear();
    credentials = null;
  }


  @override
  Future<void> setAuthCredentials() async {

    try {
      switch(loginMethod) {
        case(LoginMethod.email):
          credentials = fba.EmailAuthProvider.credential(
              email: emailController.text.trim(),
              password: passwordController.text.trim()
          );
          break;
        case(LoginMethod.facebook):
          credentials = fba.FacebookAuthProvider.credential(_fbAccessToken);
          break;
        case(LoginMethod.apple):
          final rawNonce = generateNonce();
          final nonce = SecurityUtilities.sha256ofString(rawNonce);

          AuthorizationCredentialAppleID appleCredential = await SignInWithApple.getAppleIDCredential(
            scopes: [
              AppleIDAuthorizationScopes.email,
              AppleIDAuthorizationScopes.fullName,
            ],
            nonce: nonce, // Pass hashed nonce to Apple
          );

          AppConfig.logger.d('Apple idToken: ${appleCredential.identityToken}');
          AppConfig.logger.d('Apple nonce: $nonce');
          AppConfig.logger.d('Apple rawNonce: $rawNonce');


          credentials = fba.OAuthProvider("apple.com").credential(
            idToken: appleCredential.identityToken,
            accessToken: appleCredential.authorizationCode,
            rawNonce: rawNonce, // Pass raw nonce to Firebase
          );

          break;
        case(LoginMethod.google):
          final googleAuthService = Sint.find<GoogleAuthService>();
          final success = await googleAuthService.signIn();
          if (!success) {
            AppConfig.logger.d("Google Sign-In was cancelled or unavailable");
            credentials = null;
            break;
          }
          final idToken = googleAuthService.idToken;
          if (idToken == null) {
            AppConfig.logger.e("Google Sign-In failed: No idToken received");
            credentials = null;
            break;
          }
          credentials = fba.GoogleAuthProvider.credential(
              idToken: idToken,
          );
          break;
        case(LoginMethod.spotify):
          break;
        case(LoginMethod.notDetermined):
          await signOut();
          break;
      }
    } catch (e, st) {
      NeomErrorLogger.recordError(e, st, module: 'neom_auth', operation: 'setAuthCredentials');
      AppUtilities.showSnackBar(
        title: AuthTranslationConstants.loginError.tr,
        message: e.toString(),
      );
    }

  }

  @override
  void setAuthStatus(AuthStatus status) {
    authStatus.value = status;
  }

  @override
  void setIsLoading(bool loading) {
    isLoading.value = loading;
  }

  @override
  Future<void> verifyPhoneNumber(String phoneNumber) async {
    await _auth.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      timeout: const Duration(seconds: 60),
      verificationCompleted: (fba.PhoneAuthCredential credential) async {
        // Si el número es automáticamente verificado
        await _auth.signInWithCredential(credential);
      },
      verificationFailed: (fba.FirebaseAuthException e) {
        // Manejar errores, por ejemplo si el formato del número es incorrecto
        if (e.code == 'invalid-phone-number') {
          AppConfig.logger.w('El número de teléfono no es válido.');
        }
      },
      codeSent: (String verificationId, int? resendToken) {
        phoneVerificationId = verificationId;
        // Guardar el `verificationId` y pedir al usuario que ingrese el código enviado por SMS
        AppConfig.logger.d('Código de verificación enviado with verificationId $verificationId');
      },
      codeAutoRetrievalTimeout: (String verificationId) {
        // Manejar el tiempo de espera si no se recibe el código automáticamente
        AppConfig.logger.w('Tiempo de espera para la verificación agotado');
      },
    );
  }

  @override
  Future<bool> validateSmsCode(String smsCode) async {
    fba.PhoneAuthCredential credential = fba.PhoneAuthProvider.credential(
      verificationId: phoneVerificationId,
      smsCode: smsCode,
    );

    try {
      // Autenticación con las credenciales del código SMS
      await _auth.signInWithCredential(credential);
      isPhoneAuth = true;
      return true;
    } catch(e, st) {
      NeomErrorLogger.recordError(e, st, module: 'neom_auth', operation: 'validateSmsCode');
    }
    return false;
  }

  @override
  Future<void> deleteFbaUser(fba.AuthCredential credential) async {
    await _fbaUser.value?.reauthenticateWithCredential(credential);
    await _fbaUser.value?.delete();
    await signOut();
  }

  @override
  fba.AuthCredential? getAuthCredentials() {
    return credentials;
  }

  @override
  AuthStatus getAuthStatus() {
    return authStatus.value;
  }

  @override
  void setIsPhoneAuth(bool value) {
    isPhoneAuth = value;
  }

  @override
  SignedInWith get signedInWith => _signedInWith;

  @override
  set signedInWith(SignedInWith signedInWith) {
    _signedInWith = signedInWith;
  }

  @override
  fba.FirebaseAuth get auth => _auth;

  @override
  fba.User? get fbaUser => _fbaUser.value;

  @override
  set fbaUser(fba.User? fbaUser) {
    _fbaUser.value = fbaUser;
  }

  @override
  void loginAsGuest() {
    AppConfig.logger.d("Entering as Guest");
    AppConfig.instance.isGuestMode = true;
    userServiceImpl.user = AppUser();
    userServiceImpl.profile = AppProfile();
    Sint.offAllNamed(AppRouteConstants.root);
  }

  void onGuestLoginSuccess() {
    // Verificamos si venimos redirigidos de una acción protegida
    if (Sint.arguments != null && Sint.arguments['nextRoute'] != null) {
      String nextRoute = Sint.arguments['nextRoute'];
      dynamic nextArgs = Sint.arguments['nextArgs'];

      // Vamos directo a la acción que el usuario quería hacer (ej. Crear Evento)
      Sint.offNamed(nextRoute, arguments: nextArgs);
    } else {
      // Flujo normal
      Sint.offAllNamed(AppRouteConstants.root);
    }
  }

}
