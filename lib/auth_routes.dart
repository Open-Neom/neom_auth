import 'package:neom_core/ui/deferred_loader.dart';
import 'package:sint/sint.dart';
import 'package:neom_commons/ui/splash_page.dart' deferred as splash;
import 'package:neom_core/utils/constants/app_route_constants.dart';
import 'ui/forgot_password/forgot_password_page.dart' deferred as forgotPwd;
import 'ui/login/login_page.dart' deferred as login;
import 'ui/signup/signup_page.dart' deferred as signup;

class AuthRoutes {

  static final List<SintPage<dynamic>> routes = [
    SintPage(
      name: AppRouteConstants.login,
      page: () => DeferredLoader(login.loadLibrary, () => login.LoginPage()),
    ),
    SintPage(
      name: AppRouteConstants.forgotPassword,
      page: () => DeferredLoader(forgotPwd.loadLibrary, () => forgotPwd.ForgotPasswordPage()),
    ),
    SintPage(
      name: AppRouteConstants.forgotPasswordSending,
      page: () => DeferredLoader(splash.loadLibrary, () => splash.SplashPage()),
    ),
    SintPage(
      name: AppRouteConstants.signup,
      page: () => DeferredLoader(signup.loadLibrary, () => signup.SignupPage()),
    ),
    SintPage(
      name: AppRouteConstants.logout,
      page: () => DeferredLoader(splash.loadLibrary, () => splash.SplashPage()),
    ),
    SintPage(
      name: AppRouteConstants.accountRemove,
      page: () => DeferredLoader(splash.loadLibrary, () => splash.SplashPage()),
    ),
    SintPage(
      name: AppRouteConstants.profileRemove,
      page: () => DeferredLoader(splash.loadLibrary, () => splash.SplashPage()),
    ),
  ];

}
