import '../../utils/constants/auth_translation_constants.dart';

class AuthEnTranslations {
  static const Map<String, String> values = {
    AuthTranslationConstants.accountSignUp: 'Account Sign Up',
    AuthTranslationConstants.signUpFailed:
        'We could not create your account. Please try again.',
    AuthTranslationConstants.signUpWeakPassword:
        'The password does not meet the security requirements. Choose a stronger password.',
    AuthTranslationConstants.authMethodUnavailable:
        'Email and password registration is currently unavailable.',
    AuthTranslationConstants.authNetworkError:
        'Unable to connect. Check your internet connection and try again.',
    AuthTranslationConstants.authTooManyRequests:
        'Too many attempts. Wait a few minutes and try again.',
    AuthTranslationConstants.passwordResetRequested:
        'If an account exists for that email, you will receive instructions to reset your password.',
    AuthTranslationConstants.passwordResetFailed:
        'We could not request a password reset. Please try again.',
    AuthTranslationConstants.accountLoadErrorTitle:
        'Unable to load your account',
    AuthTranslationConstants.accountLoadErrorMessage:
        'Authentication succeeded, but we couldn\'t load your account information. Don\'t sign up again to resolve this error. Retry or explore as a guest.',
    AuthTranslationConstants.retryAccountLoad: 'Retry loading account',
    AuthTranslationConstants.confirmPassword: 'Confirm password',
    AuthTranslationConstants.dontHaveAnAccount: 'Don\'t have an account? ',
    AuthTranslationConstants.emailNotFound:
        'The provided email is not associated with any account.',
    AuthTranslationConstants.enterPassword: 'Enter your password',
    AuthTranslationConstants.forgotPassword: 'Forgot password?',
    AuthTranslationConstants.loadingAccount: 'Loading account',
    AuthTranslationConstants.passwordResetInstruction:
        'Enter your email to receive instructions on how to reset your password',
    AuthTranslationConstants.signIn: 'Sign In',
    AuthTranslationConstants.signInWith: 'Sign in with',
    AuthTranslationConstants.signUp: 'Sign Up',
    AuthTranslationConstants.somewhereUniverse: 'Somewhere in the universe',
    AuthTranslationConstants.youWillFindMsg:
        'Here you will find users interested in meditation for an activity or for the occasion.',
  };
}
