import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:sint/sint.dart';
import 'package:neom_commons/app_flavour.dart';
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
      builder: (controller) => Scaffold(
        backgroundColor: AppFlavour.getBackgroundColor(),
        body: SafeArea(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 40,),
            alignment: AlignmentGeometry.center,
            width: AppTheme.fullWidth(context),
              height: AppTheme.fullHeight(context),
                decoration: AppTheme.appBoxDecoration,
              child: Obx(()=> controller.isLoading.value ? AppCircularProgressIndicator(
                subtitle: AuthTranslationConstants.loadingAccount.tr,
                fontSize: 20,
              ) : SingleChildScrollView(
                child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  HeaderIntro(title: kDebugMode ? CoreConstants.dev : "", showLogo: true,),
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
                              && ((Platform.isAndroid) || (Platform.isIOS && controller.isIOS16OrHigher))
                              ? Column(
                            children: [
                              buildSignInWithText(),
                              buildSocialBtnRow(controller),
                            ],
                          ) : const SizedBox.shrink(),
                          buildSignupBtn(controller),
                          TextButton(
                            onPressed: () => controller.loginAsGuest(),
                            child: Text(
                              AppTranslationConstants.exploreAsGuest.tr,
                              style: TextStyle(
                                  color: Colors.white70,
                                  decoration: TextDecoration.underline
                              ),
                            ),
                          )
                        ]
                      )
                  ),
                  if(MediaQuery.of(context).orientation == Orientation.landscape) AppTheme.heightSpace50,
                ],
              ),),
            ),),
        ),
      ),
    );
  }


}
