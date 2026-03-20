import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:sint/sint.dart';
import 'package:neom_commons/app_flavour.dart';
import 'package:neom_commons/ui/theme/app_color.dart';
import 'package:neom_commons/ui/theme/app_theme.dart';
import 'package:neom_commons/ui/widgets/core_widgets.dart';
import 'package:neom_commons/utils/constants/app_page_id_constants.dart';
import 'package:neom_commons/utils/constants/translations/app_translation_constants.dart';
import 'package:neom_commons/utils/constants/translations/common_translation_constants.dart';
import 'package:neom_commons/utils/external_utilities.dart';
import 'package:neom_core/app_properties.dart';

import '../../utils/constants/auth_translation_constants.dart';
import '../widgets/signup_widgets.dart';
import 'signup_controller.dart';


class SignupPage extends StatelessWidget {
  const SignupPage({super.key});

  @override
  Widget build(BuildContext context) {
    return SintBuilder<SignUpController>(
      id: AppPageIdConstants.signUp,
      init: SignUpController(),
      builder: (controller) {
        if (kIsWeb) {
          return _buildWebSignup(context, controller);
        }
        return _buildMobileSignup(context, controller);
      },
    );
  }

  /// Web: card centrada glassmorphism sobre fondo oscuro con Tab navigation
  Widget _buildWebSignup(BuildContext context, SignUpController controller) {
    return Scaffold(
      backgroundColor: AppColor.darkBackground,
      body: Obx(() => Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.center,
            radius: 1.2,
            colors: [
              AppColor.getMain().withAlpha(50),
              AppColor.darkBackground,
            ],
          ),
        ),
        child: Stack(
          children: [
            // Branding sutil esquina superior izquierda
            Positioned(
              top: 32,
              left: 40,
              child: Text(
                'EMXI',
                style: TextStyle(
                  color: AppColor.textTertiary,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  fontFamily: AppTheme.fontFamily,
                  letterSpacing: 4,
                ),
              ),
            ),

            // Botón de regreso
            Positioned(
              top: 28,
              left: 100,
              child: IconButton(
                icon: Icon(Icons.arrow_back, color: AppColor.textSecondary),
                onPressed: () => Sint.back(),
              ),
            ),

            // Card centrada
            Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(vertical: 40),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 460),
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 24),
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 32),
                    decoration: BoxDecoration(
                      color: AppColor.white10,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: AppColor.borderMedium,
                        width: 1,
                      ),
                    ),
                    child: Form(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Logo compacto
                          SizedBox(
                            height: 60,
                            child: AppFlavour.getSplashImage(),
                          ),

                          const SizedBox(height: 16),

                          // Titulo
                          Text(
                            AuthTranslationConstants.signUp.tr,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              fontFamily: AppTheme.fontFamily,
                            ),
                          ),

                          const SizedBox(height: 8),

                          // Subtitulo
                          Text(
                            AuthTranslationConstants.youWillFindMsg.tr,
                            style: TextStyle(
                              color: AppColor.textSecondary,
                              fontSize: 13,
                              fontFamily: AppTheme.fontFamily,
                            ),
                            textAlign: TextAlign.center,
                          ),

                          const SizedBox(height: 16),

                          // First name + Last name
                          buildTwoEntryFields(
                            AppTranslationConstants.firstName.tr,
                            AppTranslationConstants.lastName.tr,
                            firstController: controller.firstNameController,
                            secondController: controller.lastNameController,
                            fieldsContext: context,
                            firstFocusNode: controller.firstNameFocus,
                            secondFocusNode: controller.lastNameFocus,
                            nextFocusNode: controller.usernameFocus,
                            maxFieldWidth: 170,
                          ),

                          // Username
                          buildEntryField(
                            AppTranslationConstants.username.tr,
                            controller: controller.usernameController,
                            focusNode: controller.usernameFocus,
                            nextFocusNode: controller.emailFocus,
                          ),

                          // Email
                          buildEntryField(
                            CommonTranslationConstants.enterEmail.tr,
                            controller: controller.emailController,
                            isEmail: true,
                            focusNode: controller.emailFocus,
                            nextFocusNode: controller.passwordFocus,
                          ),

                          // Password
                          buildEntryField(
                            AuthTranslationConstants.enterPassword.tr,
                            controller: controller.passwordController,
                            isPassword: true,
                            focusNode: controller.passwordFocus,
                            nextFocusNode: controller.confirmFocus,
                          ),

                          // Confirm password
                          buildEntryField(
                            AuthTranslationConstants.confirmPassword.tr,
                            controller: controller.confirmController,
                            isPassword: true,
                            focusNode: controller.confirmFocus,
                            textInputAction: TextInputAction.done,
                          ),

                          // Terms checkbox
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Checkbox(
                                value: controller.agreeTerms.value,
                                checkColor: AppColor.getMain(),
                                activeColor: Colors.white,
                                onChanged: (value) {
                                  controller.setTermsAgreement(value ?? false);
                                },
                              ),
                              Flexible(
                                child: Text(
                                  CommonTranslationConstants.iHaveReadAndAccept.tr,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppColor.textSecondary,
                                  ),
                                ),
                              ),
                              TextButton(
                                child: Text(
                                  CommonTranslationConstants.termsAndConditions.tr,
                                  style: const TextStyle(fontSize: 12),
                                ),
                                onPressed: () async {
                                  ExternalUtilities.launchURL(AppProperties.getTermsOfServiceUrl());
                                },
                              ),
                            ],
                          ),

                          // Sign up button
                          if (controller.agreeTerms.value)
                            Container(
                              margin: const EdgeInsets.only(top: 8),
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: () => controller.submit(context),
                                style: ElevatedButton.styleFrom(
                                  elevation: 5.0,
                                  padding: const EdgeInsets.all(15.0),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(30.0),
                                  ),
                                  backgroundColor: Colors.white,
                                ),
                                child: Text(
                                  AuthTranslationConstants.signUp.tr.toUpperCase(),
                                  style: const TextStyle(
                                    color: AppColor.textButton,
                                    letterSpacing: 1.5,
                                    fontSize: 18.0,
                                    fontWeight: FontWeight.bold,
                                    fontFamily: AppTheme.fontFamily,
                                  ),
                                ),
                              ),
                            ),

                          const SizedBox(height: 12),

                          // Volver al login
                          TextButton(
                            onPressed: () => Sint.back(),
                            child: Text(
                              '← ${AuthTranslationConstants.signIn.tr}',
                              style: TextStyle(
                                color: AppColor.textSecondary,
                                decoration: TextDecoration.underline,
                                decorationColor: AppColor.textMuted,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      )),
    );
  }

  /// Mobile: layout original sin cambios
  Widget _buildMobileSignup(BuildContext context, SignUpController controller) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: SintAppBar(backgroundColor: Colors.transparent),
      backgroundColor: AppColor.scaffold,
      body: SingleChildScrollView(
        child: Obx(() => Container(
          width: AppTheme.fullWidth(context),
          height: AppTheme.fullHeight(context),
          decoration: AppTheme.appBoxDecoration,
          padding: const EdgeInsets.symmetric(horizontal: 30),
          child: Form(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                buildLabel(context, CommonTranslationConstants.welcomeToApp.tr, AuthTranslationConstants.youWillFindMsg.tr),
                buildTwoEntryFields(AppTranslationConstants.firstName.tr, AppTranslationConstants.lastName.tr,
                    firstController: controller.firstNameController, secondController: controller.lastNameController, fieldsContext: context),
                buildEntryField(AppTranslationConstants.username.tr, controller: controller.usernameController),
                buildEntryField(CommonTranslationConstants.enterEmail.tr,
                    controller: controller.emailController, isEmail: true),
                buildEntryField(AuthTranslationConstants.enterPassword.tr,
                    controller: controller.passwordController, isPassword: true),
                buildEntryField(AuthTranslationConstants.confirmPassword.tr,
                    controller: controller.confirmController, isPassword: true),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Checkbox(
                      value: controller.agreeTerms.value,
                      onChanged: (value) {
                        controller.setTermsAgreement(value ?? false);
                      },
                    ),
                    Text(CommonTranslationConstants.iHaveReadAndAccept.tr,
                      style: const TextStyle(fontSize: 12),
                    ),
                    TextButton(
                        child: Text(CommonTranslationConstants.termsAndConditions.tr,
                          style: const TextStyle(fontSize: 12),
                        ),
                        onPressed: () async {
                          ExternalUtilities.launchURL(AppProperties.getTermsOfServiceUrl());
                        }
                    ),
                  ],
                ),
                !controller.agreeTerms.value ? const SizedBox.shrink() : Container(
                  margin: const EdgeInsets.symmetric(vertical: 15),
                  width: MediaQuery.of(context).size.width/2,
                  child: TextButton(
                    onPressed: () => controller.submit(context),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 10),
                      backgroundColor: AppColor.surfaceBright,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(40)),),
                    child: Text(AuthTranslationConstants.signUp.tr, style: const TextStyle(color: Colors.white,fontSize: 16.0,
                        fontWeight: FontWeight.bold)),
                  ),
                ),
                const Divider(height: 30),
                const SizedBox(height: 30),
              ],
            ),
          ),
        ),),
      ),
    );
  }
}
