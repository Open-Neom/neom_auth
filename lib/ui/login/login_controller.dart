import 'package:firebase_auth/firebase_auth.dart' as fba;
import 'package:neom_core/utils/platform/core_io.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:sint/sint.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:neom_commons/utils/app_utilities.dart';
import 'package:neom_commons/utils/constants/translations/message_translation_constants.dart';
import 'package:neom_commons/utils/device_utilities.dart';
import 'package:neom_commons/utils/security_utilities.dart';
import 'package:neom_core/app_config.dart';
import 'package:neom_core/app_properties.dart';
import 'package:neom_core/data/firestore/constants/app_firestore_constants.dart';
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

  final userServiceImpl = Sint.find<UserService>();

  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;
  Rx<AuthStatus> authStatus = AuthStatus.notDetermined.obs;

  String _userId = "";
  final String _fbAccessToken = "";
  fba.AuthCredential? credentials;

  fba.FirebaseAuth _auth = fba.FirebaseAuth.instance;
  final Rxn<fba.User> _fbaUser = Rxn<fba.User>();

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
    _fbaUser.bindStream(_auth.authStateChanges());
    //_fbaUser.value = _auth.currentUser;
    ///DEPRECATED ever<fba.User?>(_fbaUser, handleAuthChanged);
    _fbaUser.listen(handleAuthChanged);

    if(kIsWeb) {
      _googleSignIn.initialize(clientId: AppProperties.getWebCliendId());
      isAppleSignInAvailable = true;
    } else if(Platform.isAndroid) {
      AppConfig.logger.t(Platform.version);
      _googleSignIn.initialize(serverClientId: AppProperties.getServerCliendId());
    } else if(Platform.isIOS) {
      isAppleSignInAvailable = DeviceUtilities.isDeviceSupportedVersion(isIOS: Platform.isIOS);
      _googleSignIn.initialize();
    } else if(Platform.isMacOS) {
      isAppleSignInAvailable = true;
      _googleSignIn.initialize(clientId: AppProperties.getWebCliendId());
    }

  }

  @override
  void onReady() {
    super.onReady();
    AppConfig.logger.t("onReady Login Controller");
    isLoading.value = false;
  }

  @override
  void onClose() {
    // NOTE: Do NOT dispose TextEditingControllers here.
    // SintBuilder manages the controller lifecycle and the widget may still
    // be rendering when onClose is called during navigation (offAllNamed).
    // The controllers will be garbage collected when the controller is disposed.
    super.onClose();
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
    authStatus.value = AuthStatus.waiting;

    if(isPhoneAuth) return;

    try {
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
              authStatus.value = AuthStatus.notDetermined;
              break;
          }
        } else if(!userServiceImpl.isNewUser && userServiceImpl.user.profiles.isEmpty) {
          AppConfig.logger.i("No Profiles found for $_userId. Please Login Again");
          authStatus.value = AuthStatus.notLoggedIn;
        } else {
          authStatus.value = AuthStatus.loggedIn;
          AppConfig.instance.isGuestMode = false;
          await Sint.find<AppHiveController>().writeProfileInfo();
        }

        if(userServiceImpl.isNewUser && userServiceImpl.user.id.isNotEmpty) {
          gotoIntroPage();
        } else if (authStatus.value == AuthStatus.loggedIn) {
          AppConfig.logger.i("User found for $_userId. Redirecting to Root Page");
          Sint.offAllNamed(AppRouteConstants.root);
        }
      }
    } catch (e) {
      AppConfig.logger.e(e.toString());
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
    Sint.toNamed(AppRouteConstants.introRequiredPermissions);
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
    } catch (e) {
      AppConfig.logger.e(e.toString());
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
    } on fba.FirebaseAuthException catch (e) {
      AppConfig.logger.e(e.toString());

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
    } catch (e) {
      AppConfig.logger.e(e.toString());
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
        // Web: use Firebase Auth signInWithPopup directly
        // (sign_in_with_apple has JS interop issues on web)
        final appleProvider = fba.OAuthProvider('apple.com');
        appleProvider.addScope('email');
        appleProvider.addScope('name');
        final userCredential = await _auth.signInWithPopup(appleProvider);
        _fbaUser.value = userCredential.user;
        authStatus.value = AuthStatus.loggedIn;
        signedInWith = SignedInWith.apple;
      } else {
        await setAuthCredentials();

        if(credentials != null) {
          fba.UserCredential userCredential = await _auth.signInWithCredential(credentials!);
          _fbaUser.value = userCredential.user;
          authStatus.value = AuthStatus.loggedIn;
          signedInWith = SignedInWith.apple;
        }
      }

    } on SignInWithAppleAuthorizationException catch (e) {

      AppConfig.logger.e(e.toString());
      _fbaUser.value = null;
      authStatus.value = AuthStatus.notLoggedIn;

      if(e.code != AuthorizationErrorCode.canceled) {
        AppUtilities.showSnackBar(
          title: MessageTranslationConstants.errorLoginApple.tr,
          message: MessageTranslationConstants.errorLoginApple.tr,
        );
      }

    } catch (e) {
      _fbaUser.value = null;
      authStatus.value = AuthStatus.notLoggedIn;
      AppConfig.logger.e(e.toString());

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
        // Web: use Firebase Auth signInWithPopup directly
        // (google_sign_in.authenticate() is not supported on web)
        final googleProvider = fba.GoogleAuthProvider();
        final userCredential = await _auth.signInWithPopup(googleProvider);
        _fbaUser.value = userCredential.user;
        authStatus.value = AuthStatus.loggedIn;
        signedInWith = SignedInWith.google;
      } else {
        await setAuthCredentials();

        if(credentials != null) {
          _fbaUser.value = (await _auth.signInWithCredential(credentials!)).user;
          authStatus.value = AuthStatus.loggedIn;
          signedInWith = SignedInWith.google;
        }
      }
    } catch (e) {
      _fbaUser.value = null;
      authStatus.value = AuthStatus.notLoggedIn;
      AppConfig.logger.e(e.toString());

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
    try {
      await _googleSignIn.signOut();
    } catch (e){
      AppConfig.logger.e(e.toString());
    }
  }

  @override
  Future<void> signOut() async {
    AppConfig.logger.d("Entering signOut method");
    try {
      await _auth.signOut();
      await googleLogout();
      clear();
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
    authStatus.value = AuthStatus.notDetermined;
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
          // FIXED: Added null safety checks for GoogleSignIn
          final GoogleSignInAccount? googleUser = await _googleSignIn.authenticate();
          if (googleUser == null) {
            AppConfig.logger.w("Google Sign-In was cancelled by user");
            credentials = null;
            break;
          }
          final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
          if (googleAuth.idToken == null) {
            AppConfig.logger.e("Google Sign-In failed: No idToken received");
            credentials = null;
            break;
          }
          credentials = fba.GoogleAuthProvider.credential(
              idToken: googleAuth.idToken,
          );
          break;
        case(LoginMethod.spotify):
          break;
        case(LoginMethod.notDetermined):
          await signOut();
          break;
      }
    } on GoogleSignInException catch (e) {
      // Handle Google Sign-In specific exceptions
      if (e.code.name == 'canceled') {
        // User cancelled the sign-in, just log it - no need to show error
        AppConfig.logger.i("Google Sign-In cancelled by user");
      } else {
        AppConfig.logger.e("Google Sign-In error: ${e.code.name} - ${e.description}");
        AppUtilities.showSnackBar(
          title: AuthTranslationConstants.loginError.tr,
          message: e.description ?? AuthTranslationConstants.loginFailed.tr,
        );
      }
    } catch (e) {
      AppConfig.logger.e(e.toString());
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
    } catch(e) {
      AppConfig.logger.e(e.toString());
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
