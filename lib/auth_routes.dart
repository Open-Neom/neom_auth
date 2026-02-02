import 'package:sint/sint.dart';
import 'package:neom_commons/ui/splash_page.dart';
import 'package:neom_core/utils/constants/app_route_constants.dart';
import 'ui/forgot_password/forgot_password_page.dart';
import 'ui/login/login_page.dart';
import 'ui/signup/signup_page.dart';

class AuthRoutes {

  static final List<SintPage<dynamic>> routes = [
    SintPage(
      name: AppRouteConstants.login,
      page: () => const LoginPage(),
    ),
    SintPage(
      name: AppRouteConstants.forgotPassword,
      page: () => const ForgotPasswordPage(),
    ),
    SintPage(
      name: AppRouteConstants.forgotPasswordSending,
      page: () => const SplashPage(),
    ),
    SintPage(
      name: AppRouteConstants.signup,
      page: () => const SignupPage(),
    ),
    SintPage(
      name: AppRouteConstants.logout,
      page: () => const SplashPage(),
    ),
    SintPage(
      name: AppRouteConstants.accountRemove,
      page: () => const SplashPage(),
    ),
    SintPage(
      name: AppRouteConstants.profileRemove,
      page: () => const SplashPage(),
    ),
  ];

}
