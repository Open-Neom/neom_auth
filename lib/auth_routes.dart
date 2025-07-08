import 'package:get/get.dart';
import 'package:neom_commons/ui/splash_page.dart';
import 'package:neom_core/utils/constants/app_route_constants.dart';
import 'ui/forgot_password/forgot_password_page.dart';
import 'ui/login/login_page.dart';
import 'ui/signup/signup_page.dart';

class AuthRoutes {

  static final List<GetPage<dynamic>> routes = [
    GetPage(
      name: AppRouteConstants.login,
      page: () => const LoginPage(),
    ),
    GetPage(
      name: AppRouteConstants.forgotPassword,
      page: () => const ForgotPasswordPage(),
    ),
    GetPage(
      name: AppRouteConstants.forgotPasswordSending,
      page: () => const SplashPage(),
    ),
    GetPage(
      name: AppRouteConstants.signup,
      page: () => const SignupPage(),
    ),
    GetPage(
      name: AppRouteConstants.logout,
      page: () => const SplashPage(),
    ),
    GetPage(
      name: AppRouteConstants.accountRemove,
      page: () => const SplashPage(),
    ),
    GetPage(
      name: AppRouteConstants.profileRemove,
      page: () => const SplashPage(),
    ),
  ];

}
