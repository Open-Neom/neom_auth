import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:sint/sint.dart';
import 'package:neom_commons/app_flavour.dart';
import 'package:neom_commons/ui/theme/app_color.dart';
import 'package:neom_commons/ui/theme/app_theme.dart';
import 'package:neom_commons/ui/widgets/appbar_child.dart';
import 'package:neom_commons/ui/widgets/core_widgets.dart';
import 'package:neom_commons/utils/constants/app_page_id_constants.dart';
import 'package:neom_commons/utils/constants/translations/app_translation_constants.dart';
import 'package:neom_commons/utils/constants/translations/common_translation_constants.dart';
import '../../utils/constants/auth_translation_constants.dart';
import 'forgot_password_controller.dart';

class ForgotPasswordPage extends StatelessWidget {
  const ForgotPasswordPage({super.key});

  @override
  Widget build(BuildContext context) {
    return SintBuilder<ForgotPasswordController>(
      id: AppPageIdConstants.forgotPassword,
      init: ForgotPasswordController(),
      builder: (controller) {
        if (kIsWeb) {
          return _buildWebForgotPassword(context, controller);
        }
        return _buildMobileForgotPassword(context, controller);
      },
    );
  }

  /// Web: card centrada glassmorphism sobre fondo oscuro
  Widget _buildWebForgotPassword(BuildContext context, ForgotPasswordController controller) {
    return Scaffold(
      backgroundColor: AppColor.darkBackground,
      body: Container(
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
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 24),
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 36),
                    decoration: BoxDecoration(
                      color: AppColor.white10,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: AppColor.borderMedium,
                        width: 1,
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Logo compacto
                        SizedBox(
                          height: 60,
                          child: AppFlavour.getSplashImage(),
                        ),

                        const SizedBox(height: 20),

                        // Titulo
                        Text(
                          AuthTranslationConstants.forgotPassword.tr,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            fontFamily: AppTheme.fontFamily,
                          ),
                        ),

                        const SizedBox(height: 12),

                        // Instrucción
                        Text(
                          AuthTranslationConstants.passwordResetInstruction.tr,
                          style: TextStyle(
                            color: AppColor.textSecondary,
                            fontSize: 14,
                            fontFamily: AppTheme.fontFamily,
                          ),
                          textAlign: TextAlign.center,
                        ),

                        const SizedBox(height: 24),

                        // Email field
                        Container(
                          decoration: AppTheme.kBoxDecorationStyle,
                          child: TextField(
                            focusNode: controller.focusNode,
                            controller: controller.emailController,
                            keyboardType: TextInputType.emailAddress,
                            style: const TextStyle(
                              color: Colors.white,
                              fontFamily: AppTheme.fontFamily,
                            ),
                            decoration: InputDecoration(
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.only(top: 14.0),
                              prefixIcon: const Icon(
                                Icons.email,
                                color: Colors.white,
                              ),
                              hintText: CommonTranslationConstants.enterEmail.tr,
                              hintStyle: AppTheme.kHintTextStyle,
                            ),
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Send button
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () => controller.submitForm(context),
                            style: ElevatedButton.styleFrom(
                              elevation: 5.0,
                              padding: const EdgeInsets.all(15.0),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30.0),
                              ),
                              backgroundColor: Colors.white,
                            ),
                            child: Text(
                              AppTranslationConstants.send.tr.toUpperCase(),
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

                        const SizedBox(height: 16),

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
          ],
        ),
      ),
    );
  }

  /// Mobile: layout original sin cambios
  Widget _buildMobileForgotPassword(BuildContext context, ForgotPasswordController controller) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBarChild(color: Colors.transparent),
      backgroundColor: AppColor.scaffold,
      body: Container(
        decoration: AppTheme.appBoxDecoration,
        padding: const EdgeInsets.symmetric(horizontal: 30),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            buildLabel(context, AuthTranslationConstants.forgotPassword.tr,
                AuthTranslationConstants.passwordResetInstruction.tr),
            Container(
              margin: const EdgeInsets.symmetric(vertical: 15),
              decoration: AppTheme.kBoxDecorationStyle,
              child: TextField(
                focusNode: controller.focusNode,
                controller: controller.emailController,
                keyboardType: TextInputType.emailAddress,
                style: const TextStyle(fontStyle: FontStyle.normal, fontWeight: FontWeight.normal),
                decoration: InputDecoration(
                  hintText: CommonTranslationConstants.enterEmail.tr,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 15, horizontal: 10),
                ),
              ),
            ),
            Container(
              margin: const EdgeInsets.symmetric(vertical: 15),
              width: MediaQuery.of(context).size.width / 2,
              child: TextButton(
                onPressed: () => controller.submitForm(context),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 10),
                  backgroundColor: AppColor.surfaceBright,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                ),
                child: Text(AppTranslationConstants.send.tr,
                  style: const TextStyle(
                    color: Colors.white, fontSize: 16.0,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
