import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:neom_commons/utils/app_utilities.dart';
import 'package:neom_commons/utils/constants/translations/message_translation_constants.dart';
import 'package:neom_core/app_config.dart';
import 'package:neom_core/domain/model/app_user.dart';
import 'package:neom_core/domain/use_cases/login_service.dart';
import 'package:neom_core/domain/use_cases/user_service.dart';
import 'package:neom_core/utils/enums/signed_in_with.dart';
import 'package:neom_core/utils/neom_error_logger.dart';
import 'package:neom_core/utils/validator.dart';
import 'package:sint/sint.dart';

import '../../domain/use_cases/signup_service.dart';
import '../../utils/constants/auth_translation_constants.dart';

class SignUpController extends SintController implements SignUpService {
  SignUpController({
    LoginService? loginService,
    UserService? userService,
    void Function(String title, String message)? showMessage,
  }) : loginServiceImpl = loginService ?? Sint.find<LoginService>(),
       userServiceImpl = userService ?? Sint.find<UserService>(),
       _showMessage = showMessage ?? _defaultShowMessage;

  final LoginService loginServiceImpl;
  final UserService userServiceImpl;
  final void Function(String title, String message) _showMessage;
  bool _submitting = false;

  static void _defaultShowMessage(String title, String message) {
    AppUtilities.showSnackBar(title: title, message: message);
  }

  final TextEditingController firstNameController = TextEditingController();
  final TextEditingController lastNameController = TextEditingController();
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmController = TextEditingController();

  // FocusNodes for Tab navigation (web)
  final FocusNode firstNameFocus = FocusNode();
  final FocusNode lastNameFocus = FocusNode();
  final FocusNode usernameFocus = FocusNode();
  final FocusNode emailFocus = FocusNode();
  final FocusNode passwordFocus = FocusNode();
  final FocusNode confirmFocus = FocusNode();

  final RxBool agreeTerms = false.obs;
  final RxBool isLoading = true.obs;

  @override
  void onInit() async {
    super.onInit();
    AppConfig.logger.d("onInit SignUp Controller");
  }

  @override
  void onReady() async {
    super.onReady();
    AppConfig.logger.d("");
    isLoading.value = false;
  }

  @override
  void onClose() {
    firstNameController.dispose();
    lastNameController.dispose();
    usernameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmController.dispose();
    firstNameFocus.dispose();
    lastNameFocus.dispose();
    usernameFocus.dispose();
    emailFocus.dispose();
    passwordFocus.dispose();
    confirmFocus.dispose();
    super.onClose();
  }

  @override
  Future<bool> submit(BuildContext context) async {
    if (_submitting) return false;
    _submitting = true;
    AppConfig.logger.d("Submitting Sign-up form");

    try {
      if (!await validateInfo()) return false;
      setUserFromSignUp();
      // Auth listeners can fire before the credential future completes.
      loginServiceImpl.signedInWith = SignedInWith.signUp;
      final fbaUser =
          (await loginServiceImpl.auth.createUserWithEmailAndPassword(
            email: emailController.text.toLowerCase().trim(),
            password: passwordController.text,
          )).user;
      if (fbaUser == null) {
        _showMessage(
          MessageTranslationConstants.accountSignUp.tr,
          AuthTranslationConstants.signUpFailed.tr,
        );
        return false;
      }
      loginServiceImpl.signedInWith = SignedInWith.signUp;
      loginServiceImpl.fbaUser = fbaUser;
      return true;
    } on FirebaseAuthException catch (e) {
      _showMessage(
        MessageTranslationConstants.accountSignUp.tr,
        signUpErrorMessage(e.code).tr,
      );
      return false;
    } catch (e, st) {
      NeomErrorLogger.recordErrorLight(
        e,
        st,
        module: 'neom_auth',
        operation: 'submitSignUp',
      );
      _showMessage(
        MessageTranslationConstants.accountSignUp.tr,
        AuthTranslationConstants.signUpFailed.tr,
      );
      return false;
    } finally {
      _submitting = false;
    }
  }

  @visibleForTesting
  static String signUpErrorMessage(String code) => switch (code) {
    'email-already-in-use' => MessageTranslationConstants.emailUsed,
    'invalid-email' => MessageTranslationConstants.invalidEmailFormat,
    'weak-password' => AuthTranslationConstants.signUpWeakPassword,
    'operation-not-allowed' => AuthTranslationConstants.authMethodUnavailable,
    'network-request-failed' => AuthTranslationConstants.authNetworkError,
    'too-many-requests' => AuthTranslationConstants.authTooManyRequests,
    _ => AuthTranslationConstants.signUpFailed,
  };

  void setUserFromSignUp() {
    AppConfig.logger.d("Getting User Info From Sign-up text fields");

    userServiceImpl.user = buildUserFromSignUp(
      homeTown: AuthTranslationConstants.somewhereUniverse.tr,
      username: usernameController.text,
      firstName: firstNameController.text,
      lastName: lastNameController.text,
      email: emailController.text,
    );
    AppConfig.logger.d('Registration draft prepared');
  }

  /// Builds the unpersisted registration draft before Firebase Auth succeeds.
  ///
  /// The password is deliberately absent: it is submitted only to Firebase
  /// Authentication and must never enter the persistable [AppUser] model.
  /// The authenticated UID is attached later by the account-loading flow.
  @visibleForTesting
  static AppUser buildUserFromSignUp({
    required String homeTown,
    required String username,
    required String firstName,
    required String lastName,
    required String email,
  }) {
    final normalizedEmail = email.toLowerCase().trim();
    return AppUser(
      homeTown: homeTown,
      photoUrl: "",
      name: username.trim(),
      firstName: firstName.trim(),
      lastName: lastName.trim(),
      email: normalizedEmail,
      // Firebase Auth assigns the UID only after account creation succeeds.
      // The login/onboarding flow attaches that UID to this unpersisted draft.
      id: '',
    );
  }

  @override
  Future<bool> validateInfo() async {
    String validatorMsg = Validator.validateName(
      firstNameController.text.trim(),
    );

    if (validatorMsg.isEmpty) {
      validatorMsg = Validator.validateName(lastNameController.text.trim());

      if (validatorMsg.isEmpty) {
        validatorMsg = Validator.validateUsername(
          usernameController.text.trim(),
        );

        if (validatorMsg.isEmpty &&
            emailController.text.isEmpty &&
            passwordController.text.isEmpty) {
          validatorMsg = MessageTranslationConstants.pleaseFillSignUpForm;
        }

        if (validatorMsg.isEmpty) {
          validatorMsg = Validator.validateEmail(emailController.text.trim());
        }
        if (validatorMsg.isEmpty) {
          validatorMsg = Validator.validatePassword(
            passwordController.text,
            confirmController.text,
          );
        }
      }
    }

    if (validatorMsg.isNotEmpty) {
      _showMessage(
        MessageTranslationConstants.accountSignUp.tr,
        validatorMsg.tr,
      );

      return false;
    }

    return true;
  }

  @override
  void setTermsAgreement(bool agree) {
    AppConfig.logger.d("Bool agreement: $agree");

    try {
      agreeTerms.value = agree;
    } catch (e, st) {
      NeomErrorLogger.recordErrorLight(
        e,
        st,
        module: 'neom_auth',
        operation: 'setTermsAgreement',
      );
    }
  }
}
