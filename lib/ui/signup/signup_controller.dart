import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:neom_commons/utils/app_utilities.dart';
import 'package:neom_commons/utils/constants/translations/message_translation_constants.dart';
import 'package:neom_core/app_config.dart';
import 'package:neom_core/data/firestore/constants/app_firestore_constants.dart';
import 'package:neom_core/data/firestore/user_firestore.dart';
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

  final loginServiceImpl = Sint.find<LoginService>();
  final userServiceImpl = Sint.find<UserService>();

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
    AppConfig.logger.d("Submitting Sign-up form");

    try {
      if(await validateInfo()) {
        setUserFromSignUp();
        // Auth listeners can fire before the credential future completes.
        loginServiceImpl.signedInWith = SignedInWith.signUp;

        User? fbaUser = (await loginServiceImpl.auth
            .createUserWithEmailAndPassword(
            email: emailController.text.toLowerCase().trim(),
            password: passwordController.text.trim())
        ).user;

        loginServiceImpl.signedInWith = SignedInWith.signUp;
        loginServiceImpl.fbaUser = fbaUser;
      }
    } on FirebaseAuthException catch (e) {
      String fbAuthExceptionMsg = "";
      switch(e.code) {
        case AppFirestoreConstants.emailInUse:
          fbAuthExceptionMsg = MessageTranslationConstants.emailUsed;
          break;
        case AppFirestoreConstants.operationNotAllowed:
          fbAuthExceptionMsg = AppFirestoreConstants.operationNotAllowed;
          break;
        case "":
          break;
      }

      AppUtilities.showSnackBar(
          title: MessageTranslationConstants.accountSignUp.tr,
          message: fbAuthExceptionMsg.tr);
      return false;
    } catch (e) {
      AppUtilities.showSnackBar(
          title: MessageTranslationConstants.accountSignUp.tr,
          message: e.toString());
      return false;
    }

    return true;
  }

  void setUserFromSignUp() {
    AppConfig.logger.d("Getting User Info From Sign-up text fields");

    try {
      userServiceImpl.user = buildUserFromSignUp(
        homeTown: AuthTranslationConstants.somewhereUniverse.tr,
        username: usernameController.text,
        firstName: firstNameController.text,
        lastName: lastNameController.text,
        email: emailController.text,
      );
    } catch (e, st) {
      NeomErrorLogger.recordError(e, st, module: 'neom_auth', operation: 'setUserFromSignUp');
    }

    AppConfig.logger.d("User Info set: ${userServiceImpl.user.toString()}");
  }

  /// Builds the application profile for a newly authenticated Firebase user.
  ///
  /// The password is deliberately absent: it is submitted only to Firebase
  /// Authentication and must never enter the persistable [AppUser] model.
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
      id: normalizedEmail,
    );
  }

  @override
  Future<bool> validateInfo() async {

    String validatorMsg = Validator.validateName(firstNameController.text);

    if (validatorMsg.isEmpty) {

      validatorMsg = Validator.validateName(lastNameController.text);

      if (validatorMsg.isEmpty) {
        validatorMsg = Validator.validateUsername(usernameController.text);

        if (validatorMsg.isEmpty && emailController.text.isEmpty
            && passwordController.text.isEmpty) {
          validatorMsg = MessageTranslationConstants.pleaseFillSignUpForm;
        }

        if (validatorMsg.isEmpty) {
          validatorMsg = Validator.validateEmail(emailController.text);
        }
        if (validatorMsg.isEmpty) {
          validatorMsg = Validator.validatePassword(
            passwordController.text, confirmController.text);
        }
      }
    }

    if(validatorMsg.isEmpty && !await UserFirestore().isAvailableEmail(emailController.text)) {
      validatorMsg = MessageTranslationConstants.emailUsed;
    }

    if (validatorMsg.isNotEmpty) {
      AppUtilities.showSnackBar(
        title: MessageTranslationConstants.accountSignUp.tr,
        message: validatorMsg.tr,
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
      NeomErrorLogger.recordError(e, st, module: 'neom_auth', operation: 'setTermsAgreement');
    }

  }

}
