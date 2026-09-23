import '../../utils/constants/auth_translation_constants.dart';

class AuthEsTranslations {
  static const Map<String, String> values = {
    AuthTranslationConstants.accountSignUp: 'Registro de cuenta',
    AuthTranslationConstants.signUpFailed:
        'No pudimos crear tu cuenta. Inténtalo de nuevo.',
    AuthTranslationConstants.signUpWeakPassword:
        'La contraseña no cumple los requisitos de seguridad. Usa una contraseña más segura.',
    AuthTranslationConstants.authMethodUnavailable:
        'El registro con correo y contraseña no está disponible por el momento.',
    AuthTranslationConstants.authNetworkError:
        'No se pudo conectar. Revisa tu conexión a internet e inténtalo de nuevo.',
    AuthTranslationConstants.authTooManyRequests:
        'Se han realizado demasiados intentos. Espera unos minutos e inténtalo de nuevo.',
    AuthTranslationConstants.passwordResetRequested:
        'Si existe una cuenta con ese correo, recibirás instrucciones para restablecer tu contraseña.',
    AuthTranslationConstants.passwordResetFailed:
        'No pudimos solicitar el restablecimiento de tu contraseña. Inténtalo de nuevo.',
    AuthTranslationConstants.accountLoadErrorTitle:
        'No se pudo cargar tu cuenta',
    AuthTranslationConstants.accountLoadErrorMessage:
        'La autenticación se completó, pero no pudimos cargar la información de tu cuenta. No vuelvas a registrarte para resolver este error. Reintenta o explora como invitado.',
    AuthTranslationConstants.retryAccountLoad: 'Reintentar carga de cuenta',
    AuthTranslationConstants.confirmPassword: 'Confirmar contraseña',
    AuthTranslationConstants.dontHaveAnAccount: '¿No tienes una cuenta? ',
    AuthTranslationConstants.emailNotFound:
        'El email proporcionado no está asociado a ninguna cuenta.',
    AuthTranslationConstants.enterPassword: 'Ingresa la contraseña',
    AuthTranslationConstants.forgotPassword: '¿Olvidaste la contraseña?',
    AuthTranslationConstants.loadingAccount: 'Cargando cuenta',
    AuthTranslationConstants.passwordResetInstruction:
        'Ingresa tu email para recibir instrucciones de como reestablecer tu contraseña',
    AuthTranslationConstants.signIn: 'Iniciar Sesión',
    AuthTranslationConstants.signInWith: 'Ingresar con',
    AuthTranslationConstants.signUp: 'Registrarse',
    AuthTranslationConstants.somewhereUniverse: 'Algún lugar en el universo',
    AuthTranslationConstants.youWillFindMsg:
        'Aquí encontrarás usuarios interesados en la meditación para alguna actividad o para la ocasión.',
  };
}
