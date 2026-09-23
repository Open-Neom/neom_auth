import '../../utils/constants/auth_translation_constants.dart';

class AuthFrTranslations {
  static const Map<String, String> values = {
    AuthTranslationConstants.signUpFailed:
        'Impossible de créer votre compte. Veuillez réessayer.',
    AuthTranslationConstants.signUpWeakPassword:
        'Le mot de passe ne respecte pas les exigences de sécurité. Choisissez un mot de passe plus sûr.',
    AuthTranslationConstants.authMethodUnavailable:
        'L’inscription par e-mail et mot de passe est momentanément indisponible.',
    AuthTranslationConstants.authNetworkError:
        'Connexion impossible. Vérifiez votre connexion Internet et réessayez.',
    AuthTranslationConstants.authTooManyRequests:
        'Trop de tentatives. Attendez quelques minutes et réessayez.',
    AuthTranslationConstants.passwordResetRequested:
        'Si un compte existe pour cette adresse e-mail, vous recevrez les instructions pour réinitialiser votre mot de passe.',
    AuthTranslationConstants.passwordResetFailed:
        'Impossible de demander la réinitialisation du mot de passe. Veuillez réessayer.',
    AuthTranslationConstants.accountSignUp: 'Créer un compte',
    AuthTranslationConstants.accountLoadErrorTitle:
        'Impossible de charger votre compte',
    AuthTranslationConstants.accountLoadErrorMessage:
        'L\'authentification a réussi, mais nous n\'avons pas pu charger les informations de votre compte. Ne vous réinscrivez pas pour résoudre cette erreur. Réessayez ou explorez l\'application en tant qu\'invité.',
    AuthTranslationConstants.retryAccountLoad: 'Réessayer de charger le compte',
    AuthTranslationConstants.confirmPassword: 'Confirmer le mot de passe',
    AuthTranslationConstants.dontHaveAnAccount: 'Vous n\'avez pas de compte ? ',
    AuthTranslationConstants.emailNotFound:
        'L\'adresse e-mail fournie n\'est associée à aucun compte.',
    AuthTranslationConstants.enterPassword: 'Entrez votre mot de passe',
    AuthTranslationConstants.forgotPassword: 'Mot de passe oublié ?',
    AuthTranslationConstants.loadingAccount: 'Chargement du compte',
    AuthTranslationConstants.passwordResetInstruction:
        'Entrez votre adresse e-mail pour recevoir les instructions de réinitialisation de votre mot de passe',
    AuthTranslationConstants.signIn: 'Se connecter',
    AuthTranslationConstants.signInWith: 'Se connecter avec',
    AuthTranslationConstants.signUp: 'S\'inscrire',
    AuthTranslationConstants.somewhereUniverse: 'Quelque part dans l\'univers',
    AuthTranslationConstants.youWillFindMsg:
        'Ici vous trouverez des utilisateurs intéressés par la méditation pour une activité ou pour l\'occasion.',
  };
}
