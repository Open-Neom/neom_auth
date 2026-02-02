import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:sint/sint.dart';
import 'package:neom_commons/utils/app_utilities.dart';
import 'package:neom_commons/utils/constants/translations/message_translation_constants.dart';
import 'package:neom_core/app_config.dart';
import 'package:neom_core/data/firestore/constants/app_firestore_constants.dart';
import 'package:neom_core/data/firestore/user_firestore.dart';
import 'package:neom_core/domain/model/app_user.dart';
import 'package:neom_core/domain/use_cases/login_service.dart';
import 'package:neom_core/domain/use_cases/user_service.dart';
import 'package:neom_core/utils/enums/signed_in_with.dart';
import 'package:neom_core/utils/validator.dart';
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
  void dispose() {
    firstNameController.dispose();
    lastNameController.dispose();
    usernameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmController.dispose();
    super.dispose();
  }

  @override
  Future<bool> submit(BuildContext context) async {
    AppConfig.logger.d("Submitting Sign-up form");

    try {

      if(await validateInfo()) {
        setUserFromSignUp();

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
      userServiceImpl.user =  AppUser(
        homeTown: AuthTranslationConstants.somewhereUniverse.tr,
        photoUrl: "",
        name: usernameController.text.trim(),
        firstName: firstNameController.text.trim(),
        lastName: lastNameController.text.trim(),
        email: emailController.text.toLowerCase().trim(),
        id: emailController.text.toLowerCase().trim(),
        password: passwordController.text.trim(),
      );
    } catch (e) {
      AppConfig.logger.e(e.toString());
    }

    AppConfig.logger.d("User Info set: ${userServiceImpl.user.toString()}");
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
    } catch (e) {
      AppConfig.logger.e(e.toString());
    }

  }

}
