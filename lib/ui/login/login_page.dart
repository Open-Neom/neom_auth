import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:neom_commons/ui/theme/app_color.dart';
import 'package:neom_commons/ui/theme/app_theme.dart';
import 'package:neom_commons/ui/widgets/app_circular_progress_indicator.dart';
import 'package:neom_commons/ui/widgets/header_intro.dart';
import 'package:neom_commons/utils/constants/app_page_id_constants.dart';
import 'package:neom_core/app_config.dart';
import 'package:neom_core/utils/constants/core_constants.dart';
import '../../utils/constants/auth_translation_constants.dart';
import '../widgets/login_widgets.dart';
import 'login_controller.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<LoginController>(
      id: AppPageIdConstants.login,
      init: LoginController(),
      builder: (_) => Scaffold(
        backgroundColor: AppColor.main50,
        body: SafeArea(
          child: SingleChildScrollView(
            child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 40,),
            width: AppTheme.fullWidth(context),
              height: AppTheme.fullHeight(context),
                decoration: AppTheme.appBoxDecoration,
              child: Obx(()=> _.isLoading.value ? AppCircularProgressIndicator(
                subtitle: AuthTranslationConstants.loadingAccount.tr,
                fontSize: 20,
              ) : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  HeaderIntro(title: kDebugMode && !kIsWeb && Platform.isAndroid ? CoreConstants.dev : "",),
                  AppTheme.heightSpace10,
                  Text(AuthTranslationConstants.signIn.tr,
                    style: const TextStyle(
                      color: Colors.white, fontSize: 25.0,
                      fontFamily: AppTheme.fontFamily,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  AppTheme.heightSpace10,
                  buildEmailTF(_),
                  AppTheme.heightSpace10,
                  buildPasswordTF(_),
                  buildForgotPasswordBtn(_),
                  SingleChildScrollView(
                      child: Column(
                        children: [
                          buildLoginBtn(_),
                          (!kIsWeb && ((Platform.isIOS && !_.isIOS13OrHigher) || (!AppConfig.instance.appInfo.googleLoginEnabled && !kDebugMode)))
                              ? const SizedBox.shrink() : Column(
                            children: [
                              buildSignInWithText(),
                              buildSocialBtnRow(_),
                            ],
                          ),
                          buildSignupBtn(_),
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
