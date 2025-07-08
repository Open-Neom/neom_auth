import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:neom_commons/ui/theme/app_color.dart';
import 'package:neom_commons/ui/theme/app_theme.dart';
import 'package:neom_commons/ui/widgets/appbar_child.dart';
import 'package:neom_commons/ui/widgets/core_widgets.dart';
import 'package:neom_commons/utils/constants/app_page_id_constants.dart';
import 'package:neom_commons/utils/constants/app_translation_constants.dart';
import 'package:neom_commons/utils/external_utilities.dart';
import 'package:neom_core/app_properties.dart';

import '../widgets/signup_widgets.dart';
import 'signup_controller.dart';


class SignupPage extends StatelessWidget {
  const SignupPage({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<SignUpController>(
      id: AppPageIdConstants.signUp,
      init: SignUpController(),
      builder: (_) => Scaffold(
        extendBodyBehindAppBar: true,
        appBar: AppBarChild(color: Colors.transparent),
        backgroundColor: AppColor.main50,
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
                    buildLabel(context, AppTranslationConstants.welcomeToApp.tr, AppTranslationConstants.youWillFindMsg.tr),
                    buildTwoEntryFields(AppTranslationConstants.firstName.tr, AppTranslationConstants.lastName.tr,
                        firstController: _.firstNameController, secondController: _.lastNameController, fieldsContext: context),
                    buildEntryField(AppTranslationConstants.username.tr, controller: _.usernameController),
                    buildEntryField(AppTranslationConstants.enterEmail.tr,
                        controller: _.emailController, isEmail: true),
                    buildEntryField(AppTranslationConstants.enterPassword.tr,
                        controller: _.passwordController, isPassword: true),
                    buildEntryField(AppTranslationConstants.confirmPassword.tr,
                        controller: _.confirmController, isPassword: true),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Checkbox(
                          value: _.agreeTerms.value,
                          onChanged: (value) {
                            _.setTermsAgreement(value ?? false);
                          },
                        ),
                        Text(AppTranslationConstants.iHaveReadAndAccept.tr,
                          style: const TextStyle(fontSize: 12),
                        ),
                        TextButton(
                            child: Text(AppTranslationConstants.termsAndConditions.tr,
                              style: const TextStyle(fontSize: 12),
                            ),
                            onPressed: () async {
                              ExternalUtilities.launchURL(AppProperties.getTermsOfServiceUrl());
                            }
                        ),
                      ],
                    ),
                    !_.agreeTerms.value ? const SizedBox.shrink() : Container(
                      margin: const EdgeInsets.symmetric(vertical: 15),
                      width: MediaQuery.of(context).size.width/2,
                      child: TextButton(
                        onPressed: () => _.submit(context),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 10),
                          backgroundColor: AppColor.getMain(),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(40)),),
                        child: Text(AppTranslationConstants.signUp.tr, style: const TextStyle(color: Colors.white,fontSize: 16.0,
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
      ),
    );
  }

}
