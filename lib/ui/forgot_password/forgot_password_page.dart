import 'package:flutter/material.dart';
import 'package:get/get.dart';
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
    return GetBuilder<ForgotPasswordController>(
      id: AppPageIdConstants.forgotPassword,
      init: ForgotPasswordController(),
      builder: (_) => Scaffold(
        extendBodyBehindAppBar: true,
        appBar: AppBarChild(color: Colors.transparent),
        backgroundColor: AppColor.main50,
        body: Container(
            decoration: AppTheme.appBoxDecoration,
            padding: const EdgeInsets.symmetric(horizontal: 30),
            child:Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                buildLabel(context, AuthTranslationConstants.forgotPassword.tr,
                    AuthTranslationConstants.passwordResetInstruction.tr),
                Container(
                  margin: const EdgeInsets.symmetric(vertical: 15),
                  decoration: AppTheme.kBoxDecorationStyle,
                  child: TextField(
                    focusNode: _.focusNode,
                    controller: _.emailController,
                    keyboardType: TextInputType.emailAddress,
                    style: const TextStyle(fontStyle: FontStyle.normal,fontWeight: FontWeight.normal),
                    decoration: InputDecoration(
                        hintText: CommonTranslationConstants.enterEmail.tr,
                        border: InputBorder.none,
                        contentPadding:const EdgeInsets.symmetric(vertical: 15,horizontal: 10)
                    ),
                  ),
                ),
                Container(
                    margin: const EdgeInsets.symmetric(vertical: 15),
                    width: MediaQuery.of(context).size.width/2,
                    child: TextButton(
                      onPressed: () => _.submitForm(context),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 30,vertical: 10),
                        backgroundColor: AppColor.getMain(),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                      ),
                      child: Text(AppTranslationConstants.send.tr, style: const TextStyle(color: Colors.white,fontSize: 16.0,
                          fontWeight: FontWeight.bold)),
                    )
                )
              ],
            )
        ),
      ),
    );
  }
  
}
