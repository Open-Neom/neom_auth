import '../../utils/constants/auth_translation_constants.dart';

class AuthDeTranslations {
  static const Map<String, String> values = {
    AuthTranslationConstants.signUpFailed:
        'Dein Konto konnte nicht erstellt werden. Bitte versuche es erneut.',
    AuthTranslationConstants.signUpWeakPassword:
        'Das Passwort erfüllt die Sicherheitsanforderungen nicht. Wähle ein sichereres Passwort.',
    AuthTranslationConstants.authMethodUnavailable:
        'Die Registrierung mit E-Mail und Passwort ist derzeit nicht verfügbar.',
    AuthTranslationConstants.authNetworkError:
        'Verbindung fehlgeschlagen. Prüfe deine Internetverbindung und versuche es erneut.',
    AuthTranslationConstants.authTooManyRequests:
        'Zu viele Versuche. Warte einige Minuten und versuche es erneut.',
    AuthTranslationConstants.passwordResetRequested:
        'Falls ein Konto mit dieser E-Mail-Adresse existiert, erhältst du Anweisungen zum Zurücksetzen deines Passworts.',
    AuthTranslationConstants.passwordResetFailed:
        'Das Zurücksetzen des Passworts konnte nicht angefordert werden. Bitte versuche es erneut.',
    AuthTranslationConstants.accountSignUp: 'Konto registrieren',
    AuthTranslationConstants.accountLoadErrorTitle:
        'Dein Konto konnte nicht geladen werden',
    AuthTranslationConstants.accountLoadErrorMessage:
        'Die Authentifizierung war erfolgreich, aber deine Kontoinformationen konnten nicht geladen werden. Registriere dich nicht erneut, um diesen Fehler zu beheben. Versuche es noch einmal oder erkunde die App als Gast.',
    AuthTranslationConstants.retryAccountLoad: 'Konto erneut laden',
    AuthTranslationConstants.confirmPassword: 'Passwort bestätigen',
    AuthTranslationConstants.dontHaveAnAccount: 'Noch kein Konto? ',
    AuthTranslationConstants.emailNotFound:
        'Die angegebene E-Mail-Adresse ist keinem Konto zugeordnet.',
    AuthTranslationConstants.enterPassword: 'Passwort eingeben',
    AuthTranslationConstants.forgotPassword: 'Passwort vergessen?',
    AuthTranslationConstants.loadingAccount: 'Konto wird geladen',
    AuthTranslationConstants.passwordResetInstruction:
        'Geben Sie Ihre E-Mail-Adresse ein, um Anweisungen zum Zurücksetzen Ihres Passworts zu erhalten',
    AuthTranslationConstants.signIn: 'Anmelden',
    AuthTranslationConstants.signInWith: 'Anmelden mit',
    AuthTranslationConstants.signUp: 'Registrieren',
    AuthTranslationConstants.somewhereUniverse: 'Irgendwo im Universum',
    AuthTranslationConstants.youWillFindMsg:
        'Hier finden Sie Nutzer, die an Meditation für eine Aktivität oder für den Anlass interessiert sind.',
  };
}
