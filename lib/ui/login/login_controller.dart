import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart' as fba;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:neom_commons/utils/app_utilities.dart';
import 'package:neom_commons/utils/constants/app_page_id_constants.dart';
import 'package:neom_commons/utils/constants/message_translation_constants.dart';
import 'package:neom_commons/utils/device_utilities.dart';
import 'package:neom_commons/utils/security_utilities.dart';
import 'package:neom_core/app_config.dart';
import 'package:neom_core/data/firestore/constants/app_firestore_constants.dart';
import 'package:neom_core/data/implementations/user_controller.dart';
import 'package:neom_core/domain/use_cases/login_service.dart';
import 'package:neom_core/utils/constants/app_route_constants.dart';
import 'package:neom_core/utils/enums/auth_status.dart';
import 'package:neom_core/utils/validator.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import '../../utils/enums/login_method.dart';
import '../../utils/enums/signed_in_with.dart';

class LoginController extends GetxController implements LoginService {

  final userController = Get.find<UserController>();

  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  Rx<AuthStatus> authStatus = AuthStatus.notDetermined.obs;
  GoogleSignIn _googleSignIn = GoogleSignIn();

  //TODO Verify if its not needed
  //final SignInWithApple _appleSignIn = SignInWithApple();

  String _userId = "";
  final String _fbAccessToken = "";
  fba.AuthCredential? credentials;

  fba.FirebaseAuth auth = fba.FirebaseAuth.instance;
  final Rxn<fba.User> fbaUser = Rxn<fba.User>();

  SignedInWith signedInWith = SignedInWith.notDetermined;
  LoginMethod loginMethod = LoginMethod.notDetermined;
  
  final RxBool isLoading = true.obs;
  final RxBool isButtonDisabled = false.obs;

  bool isPhoneAuth = false;
  String phoneVerificationId = '';

  bool isIOS13OrHigher = false;

  @override
  void onInit() {
    super.onInit();
    AppConfig.logger.t("onInit Login Controller");
    // appInfo.value = AppInfo();
    fbaUser.value = auth.currentUser;
    ever<fba.User?>(fbaUser, handleAuthChanged);
    fbaUser.bindStream(auth.authStateChanges());

    if(kIsWeb) {
      _googleSignIn = GoogleSignIn(clientId: '444807211272-qlk8fl7dp6lg5d5o7hq6dkv2rj80m8kt.apps.googleusercontent.com');
    } else {
      if(Platform.isIOS) {

      }
    }
    if(Platform.isIOS && !kIsWeb ) {
      isIOS13OrHigher = DeviceUtilities.isDeviceSupportedVersion(isIOS: Platform.isIOS);
    } else if (Platform.isAndroid) {
      AppConfig.logger.t(Platform.version);
    }
  }

  @override
  void onReady() {
    super.onReady();
    AppConfig.logger.t("onReady Login Controller");
    isLoading.value = false;
  }

  @override
  Future<void> handleAuthChanged(fba.User? user) async {
    AppConfig.logger.d("handleAuthChanged");
    authStatus.value = AuthStatus.waiting;

    if(isPhoneAuth) return;

    try {
      if(auth.currentUser == null) {
        authStatus.value = AuthStatus.notLoggedIn;
        auth = fba.FirebaseAuth.instance;
      } else if (user == null && auth.currentUser != null) {
        authStatus.value = AuthStatus.notLoggedIn;
        user = auth.currentUser!;
      } else if(user != null) {
        if(user.providerData.isNotEmpty) {
          _userId = user.providerData.first.uid!;
          if(Validator.isEmail(_userId) || (user.providerData.first.email?.isNotEmpty ?? false)) {
            String email = Validator.isEmail(_userId) ? _userId : user.providerData.first.email ?? '';
            await userController.setUserByEmail(email);
          } else if(_userId.isNotEmpty) {
            await userController.setUserById(_userId);
          }
        }

        if(userController.user.id.isEmpty) {
          AppConfig.logger.d("User not found in Firestore for $_userId.");
          switch(signedInWith) {
            case(SignedInWith.signUp):
              gotoIntroPage();
              break;
            case(SignedInWith.email):
            case(SignedInWith.google):
            case(SignedInWith.apple):
              userController.getUserFromFirebase(user);
              break;
            case(SignedInWith.facebook):
            case(SignedInWith.spotify):
              break;
            case(SignedInWith.notDetermined):
              authStatus.value = AuthStatus.notDetermined;
              break;
          }
        } else if(!userController.isNewUser && userController.user.profiles.isEmpty) {
          AppConfig.logger.i("No Profiles found for $_userId. Please Login Again");
          authStatus.value = AuthStatus.notLoggedIn;
        } else {
          authStatus.value = AuthStatus.loggedIn;
        }

        if(userController.isNewUser && userController.user.id.isNotEmpty) {
          gotoIntroPage();
        } else {
          AppConfig.logger.i("User found for $_userId. Redirecting to Root Page");
          Get.offAllNamed(AppRouteConstants.root);
        }
      }
    } catch (e) {
      AppConfig.logger.e(e.toString());
      AppUtilities.showSnackBar(
        title: MessageTranslationConstants.errorHandlingAuth,
        message: e.toString()
      );
      Get.offAllNamed(AppRouteConstants.root);
    } finally {
      isLoading.value = false;
    }

    update([AppPageIdConstants.login, AppPageIdConstants.root]);
  }

  void gotoIntroPage() {
    AppConfig.logger.i("New User found for $_userId. Redirecting to Intro Page");
    authStatus.value = AuthStatus.loggedIn;
    Get.toNamed(AppRouteConstants.introRequiredPermissions);
  }

  Future<void> handleLogin(LoginMethod logMethod) async {

    isButtonDisabled.value = true;
    isLoading.value = true;
    // update([AppPageIdConstants.login]);

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
      fba.UserCredential userCredential = await auth.signInWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim()
      );

       if(userCredential.user != null) {
         emailUser = userCredential.user;
         fbaUser.value = emailUser;
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
      await setAuthCredentials();

      if(credentials != null) {
        fba.UserCredential userCredential = await auth.signInWithCredential(credentials!);
        fbaUser.value = userCredential.user;
        authStatus.value = AuthStatus.loggedIn;
        signedInWith = SignedInWith.apple;
      }

    } on SignInWithAppleAuthorizationException catch (e) {

      AppConfig.logger.e(e.toString());
      fbaUser.value = null;
      authStatus.value = AuthStatus.notLoggedIn;

      if(e.code != AuthorizationErrorCode.canceled) {
        AppUtilities.showSnackBar(
          title: MessageTranslationConstants.errorLoginApple.tr,
          message: MessageTranslationConstants.errorLoginApple.tr,
        );
      }

    } catch (e) {
      fbaUser.value = null;
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
       await setAuthCredentials();

      if(credentials != null) {
        fbaUser.value = (await auth.signInWithCredential(credentials!)).user;
        authStatus.value = AuthStatus.loggedIn;
        signedInWith = SignedInWith.google;
      }
    } catch (e) {
      fbaUser.value = null;
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
      await auth.signOut();
      await googleLogout();
      clear();
      Get.offAllNamed(AppRouteConstants.login);
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
    fbaUser.value = null;
    authStatus.value = AuthStatus.notDetermined;
    isButtonDisabled.value = false;
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
          GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
          if(googleUser != null) {
            GoogleSignInAuthentication googleAuth = await googleUser.authentication;
            credentials = fba.GoogleAuthProvider.credential(
                idToken: googleAuth.idToken,
                accessToken: googleAuth.accessToken
            );
          }
          break;
        case(LoginMethod.spotify):
          break;
        case(LoginMethod.notDetermined):
          await signOut();
          break;
      }
    } catch (e) {
      AppConfig.logger.e(e.toString());
      AppUtilities.showSnackBar(
        title: MessageTranslationConstants.underConstruction.tr,
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
    await auth.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      timeout: const Duration(seconds: 60),
      verificationCompleted: (fba.PhoneAuthCredential credential) async {
        // Si el número es automáticamente verificado
        await auth.signInWithCredential(credential);
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
      await auth.signInWithCredential(credential);
      isPhoneAuth = true;
      return true;
    } catch(e) {
      AppConfig.logger.e(e.toString());
    }
    return false;
  }

  @override
  Future<void> deleteFbaUser(fba.AuthCredential credential) async {
    await fbaUser.value?.reauthenticateWithCredential(credential);
    await fbaUser.value?.delete();
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

}
