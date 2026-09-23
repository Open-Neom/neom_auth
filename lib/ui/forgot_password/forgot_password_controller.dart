import 'package:firebase_auth/firebase_auth.dart' as fba;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:neom_commons/utils/constants/translations/common_translation_constants.dart';
import 'package:neom_commons/utils/constants/translations/message_translation_constants.dart';
import 'package:neom_core/app_config.dart';
import 'package:neom_core/utils/constants/app_route_constants.dart';
import 'package:neom_core/utils/neom_error_logger.dart';
import 'package:neom_core/utils/validator.dart';
import 'package:sint/sint.dart';

import '../../domain/use_cases/forgot_password_service.dart';
import '../../utils/constants/auth_translation_constants.dart';

class ForgotPasswordController extends SintController
    implements ForgotPasswordService {
  ForgotPasswordController({
    fba.FirebaseAuth? firebaseAuth,
    void Function(String title, String message)? showMessage,
    void Function()? onResetRequested,
  }) : auth = firebaseAuth ?? fba.FirebaseAuth.instance,
       _showMessage = showMessage ?? _defaultShowMessage,
       _onResetRequested = onResetRequested ?? _defaultResetRequested;

  final void Function(String title, String message) _showMessage;
  final void Function() _onResetRequested;

  static void _defaultShowMessage(String title, String message) {
    Sint.snackbar(title, message, snackPosition: SnackPosition.bottom);
  }

  static void _defaultResetRequested() {
    Sint.offAllNamed(AppRouteConstants.login);
  }

  final FocusNode focusNode = FocusNode();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();

  fba.FirebaseAuth auth;

  final RxBool isLoading = true.obs;
  final RxBool isButtonDisabled = false.obs;

  @override
  void onInit() async {
    super.onInit();
    AppConfig.logger.d("onInit ForgotPassword Controller");
    emailController.text = '';
    focusNode.requestFocus();
  }

  @override
  void onReady() async {
    super.onReady();
    AppConfig.logger.d("onReady ForgotPassword Controller");

    isLoading.value = false;
  }

  @override
  void onClose() {
    emailController.dispose();
    nameController.dispose();
    focusNode.dispose();
    super.onClose();
  }

  @override
  Future<bool> submitForm(BuildContext context) async {
    if (isButtonDisabled.value) return false;
    isButtonDisabled.value = true;
    try {
      final email = emailController.text.trim().toLowerCase();
      final validationMessage = Validator.validateEmail(email);
      if (validationMessage.isNotEmpty) {
        _showMessage(
          CommonTranslationConstants.passwordReset.tr,
          validationMessage.tr,
        );
        return false;
      }
      try {
        await auth.sendPasswordResetEmail(email: email);
      } on fba.FirebaseAuthException catch (e) {
        // Do not expose whether an address exists. Projects with email
        // enumeration protection already return success for missing accounts.
        if (e.code != 'user-not-found') rethrow;
      }
      _onResetRequested();
      _showMessage(
        CommonTranslationConstants.passwordReset.tr,
        AuthTranslationConstants.passwordResetRequested.tr,
      );
      return true;
    } on fba.FirebaseAuthException catch (e) {
      final message = switch (e.code) {
        'invalid-email' => MessageTranslationConstants.invalidEmailFormat,
        'network-request-failed' => AuthTranslationConstants.authNetworkError,
        'too-many-requests' => AuthTranslationConstants.authTooManyRequests,
        _ => AuthTranslationConstants.passwordResetFailed,
      };
      _showMessage(CommonTranslationConstants.passwordReset.tr, message.tr);
      return false;
    } catch (e, st) {
      NeomErrorLogger.recordErrorLight(
        e,
        st,
        module: 'neom_auth',
        operation: 'submitForm',
      );
      _showMessage(
        CommonTranslationConstants.passwordReset.tr,
        AuthTranslationConstants.passwordResetFailed.tr,
      );
      return false;
    } finally {
      isButtonDisabled.value = false;
    }
  }
}
