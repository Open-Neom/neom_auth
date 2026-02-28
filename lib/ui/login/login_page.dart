import 'package:flutter/foundation.dart';
import 'package:neom_core/utils/platform/core_io.dart';
import 'package:flutter/material.dart';
import 'package:sint/sint.dart';
import 'package:neom_commons/app_flavour.dart';
import 'package:neom_commons/ui/theme/app_color.dart';
import 'package:neom_commons/ui/theme/app_theme.dart';
import 'package:neom_commons/ui/widgets/app_circular_progress_indicator.dart';
import 'package:neom_commons/ui/widgets/header_intro.dart';
import 'package:neom_commons/utils/constants/app_page_id_constants.dart';
import 'package:neom_commons/utils/constants/translations/app_translation_constants.dart';
import 'package:neom_core/app_config.dart';
import 'package:neom_core/utils/constants/core_constants.dart';
import '../../utils/constants/auth_translation_constants.dart';
import '../widgets/login_widgets.dart';
import 'login_controller.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return SintBuilder<LoginController>(
      id: AppPageIdConstants.login,
      init: LoginController(),
      builder: (controller) {
        if (kIsWeb) {
          return _buildWebLogin(context, controller);
        }
        return _buildMobileLogin(context, controller);
      },
    );
  }

  /// Web: card centrada glassmorphism sobre fondo oscuro con gradiente radial
  Widget _buildWebLogin(BuildContext context, LoginController controller) {
    return Scaffold(
      backgroundColor: AppColor.darkBackground,
      body: Obx(() => controller.isLoading.value
        ? Container(
            decoration: AppTheme.appBoxDecoration,
            child: AppCircularProgressIndicator(
              subtitle: AuthTranslationConstants.loadingAccount.tr,
              fontSize: 20,
            ),
          )
        : Container(
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
                              height: 80,
                              child: AppFlavour.getSplashImage(),
                            ),

                            const SizedBox(height: 16),

                            // Título
                            Text(
                              AuthTranslationConstants.signIn.tr,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                fontFamily: AppTheme.fontFamily,
                              ),
                            ),

                            if (kDebugMode) ...[
                              const SizedBox(height: 4),
                              Text(
                                CoreConstants.dev,
                                style: TextStyle(
                                  color: AppColor.textMuted,
                                  fontSize: 12,
                                  fontFamily: AppTheme.fontFamily,
                                ),
                              ),
                            ],

                            const SizedBox(height: 24),

                            // Email field
                            buildEmailTF(controller),

                            const SizedBox(height: 12),

                            // Password field
                            buildPasswordTF(controller),

                            // Forgot password
                            buildForgotPasswordBtn(controller),

                            // Login button
                            buildLoginBtn(controller),

                            const SizedBox(height: 12),

                            // Divider sutil
                            Row(
                              children: [
                                Expanded(child: Divider(color: AppColor.borderMedium)),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 16),
                                  child: Text(
                                    AppTranslationConstants.or.tr,
                                    style: TextStyle(
                                      color: AppColor.textMuted,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                                Expanded(child: Divider(color: AppColor.borderMedium)),
                              ],
                            ),

                            const SizedBox(height: 12),

                            // Social login buttons (Google + Apple)
                            if(AppConfig.instance.appInfo.googleLoginEnabled || kDebugMode) ...[
                              buildSocialBtnRow(controller),
                              const SizedBox(height: 12),
                            ],

                            // Sign up
                            buildSignupBtn(controller),

                            const SizedBox(height: 8),

                            // Guest explore
                            TextButton(
                              onPressed: () => controller.loginAsGuest(),
                              child: Text(
                                AppTranslationConstants.exploreAsGuest.tr,
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
      ),
    );
  }

  /// Mobile: layout original sin cambios
  Widget _buildMobileLogin(BuildContext context, LoginController controller) {
    return Scaffold(
      backgroundColor: AppFlavour.getBackgroundColor(),
      body: SafeArea(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          alignment: AlignmentGeometry.center,
          width: AppTheme.fullWidth(context),
          height: AppTheme.fullHeight(context),
          decoration: AppTheme.appBoxDecoration,
          child: Obx(() => controller.isLoading.value
            ? AppCircularProgressIndicator(
                subtitle: AuthTranslationConstants.loadingAccount.tr,
                fontSize: 20,
              )
            : SingleChildScrollView(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    HeaderIntro(title: kDebugMode ? CoreConstants.dev : "", showLogo: true),
                    AppTheme.heightSpace10,
                    Text(AuthTranslationConstants.signIn.tr,
                      style: const TextStyle(
                        color: Colors.white, fontSize: 25.0,
                        fontFamily: AppTheme.fontFamily,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    AppTheme.heightSpace10,
                    buildEmailTF(controller),
                    AppTheme.heightSpace10,
                    buildPasswordTF(controller),
                    buildForgotPasswordBtn(controller),
                    SingleChildScrollView(
                      child: Column(
                        children: [
                          buildLoginBtn(controller),
                          (AppConfig.instance.appInfo.googleLoginEnabled)
                              && !kIsWeb
                              && ((Platform.isAndroid) || Platform.isMacOS || (Platform.isIOS && controller.isAppleSignInAvailable))
                              ? Column(
                                  children: [
                                    buildSignInWithText(),
                                    buildSocialBtnRow(controller),
                                  ],
                                )
                              : const SizedBox.shrink(),
                          buildSignupBtn(controller),
                          TextButton(
                            onPressed: () => controller.loginAsGuest(),
                            child: Text(
                              AppTranslationConstants.exploreAsGuest.tr,
                              style: TextStyle(
                                color: Colors.white70,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (MediaQuery.of(context).orientation == Orientation.landscape) AppTheme.heightSpace50,
                  ],
                ),
              ),
          ),
        ),
      ),
    );
  }
}
