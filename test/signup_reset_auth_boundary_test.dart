import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:neom_auth/data/translations/auth_de_translations.dart';
import 'package:neom_auth/data/translations/auth_en_translations.dart';
import 'package:neom_auth/data/translations/auth_es_translations.dart';
import 'package:neom_auth/data/translations/auth_fr_translations.dart';
import 'package:neom_auth/ui/forgot_password/forgot_password_controller.dart';
import 'package:neom_auth/ui/signup/signup_controller.dart';
import 'package:neom_auth/utils/constants/auth_translation_constants.dart';
import 'package:neom_commons/data/translations/commons/commons_es_translations.dart';
import 'package:neom_commons/utils/constants/translations/message_translation_constants.dart';
import 'package:neom_core/domain/model/app_user.dart';
import 'package:neom_core/domain/use_cases/login_service.dart';
import 'package:neom_core/domain/use_cases/user_service.dart';
import 'package:neom_core/utils/constants/app_route_constants.dart';
import 'package:neom_core/utils/enums/signed_in_with.dart';
import 'package:sint/sint.dart';

class _User extends Fake implements User {
  @override
  String get uid => 'firebase-assigned-uid';
}

class _Credential extends Fake implements UserCredential {
  _Credential(this.user);
  @override
  final User? user;
}

class _Auth extends Fake implements FirebaseAuth {
  int signupCalls = 0;
  int resetCalls = 0;
  String? email;
  String? password;
  Object? signupError;
  Object? resetError;
  Completer<UserCredential>? pendingSignup;
  Completer<void>? pendingReset;
  User? newUser = _User();

  @override
  Future<UserCredential> createUserWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    signupCalls++;
    this.email = email;
    this.password = password;
    if (signupError case final error?) throw error;
    return pendingSignup?.future ?? _Credential(newUser);
  }

  @override
  Future<void> sendPasswordResetEmail({
    required String email,
    ActionCodeSettings? actionCodeSettings,
  }) async {
    resetCalls++;
    this.email = email;
    if (resetError case final error?) throw error;
    await pendingReset?.future;
  }
}

class _Login extends Fake implements LoginService {
  _Login(this.auth);
  @override
  final FirebaseAuth auth;
  @override
  SignedInWith signedInWith = SignedInWith.email;
  @override
  User? fbaUser;
}

class _Users extends Fake implements UserService {
  @override
  AppUser user = AppUser();
}

class _Translations extends Translations {
  @override
  Map<String, Map<String, String>> get keys => {
    'en': AuthEnTranslations.values,
    'es': {...CommonsEsTranslations.values, ...AuthEsTranslations.values},
    'fr': AuthFrTranslations.values,
    'de': AuthDeTranslations.values,
  };
}

void main() {
  late _Auth auth;
  late _Login login;
  late _Users users;
  late List<String> messages;
  late SignUpController signup;
  late ForgotPasswordController reset;
  late int confirmations;

  setUp(() {
    Sint.reset();
    auth = _Auth();
    login = _Login(auth);
    users = _Users();
    messages = [];
    confirmations = 0;
    signup = SignUpController(
      loginService: login,
      userService: users,
      showMessage: (_, message) => messages.add(message),
    );
    signup.firstNameController.text = 'Test';
    signup.lastNameController.text = 'Account';
    signup.usernameController.text = 'test.account';
    signup.emailController.text = ' TEST@EXAMPLE.TEST ';
    signup.passwordController.text = ' Password9! ';
    signup.confirmController.text = ' Password9! ';
    reset = ForgotPasswordController(
      firebaseAuth: auth,
      showMessage: (_, message) => messages.add(message),
      onResetRequested: () => confirmations++,
    );
    reset.emailController.text = ' TEST@EXAMPLE.TEST ';
  });

  tearDown(() {
    signup.onClose();
    reset.onClose();
    Sint.reset();
  });

  Future<BuildContext> mount(WidgetTester tester) async {
    await tester.pumpWidget(
      SintMaterialApp(
        locale: const Locale('es'),
        translations: _Translations(),
        home: const Scaffold(body: Text('Form')),
      ),
    );
    await tester.pumpAndSettle();
    return tester.element(find.text('Form'));
  }

  testWidgets(
    'signup reaches Auth without any initialized Firebase app or Firestore',
    (tester) async {
      final context = await mount(tester);
      // A pre-auth UserFirestore() access would throw [core/no-app]. No Auth
      // account or Firestore data is created by these injected test doubles.
      expect(Firebase.apps, isEmpty);
      expect(await signup.submit(context), isTrue);
      expect(auth.signupCalls, 1);
      expect(auth.email, 'test@example.test');
      expect(auth.password, ' Password9! ', reason: 'Never trim the password');
      expect(
        users.user.id,
        isEmpty,
        reason: 'No email-based persisted identity',
      );
      expect(users.user.email, 'test@example.test');
      expect(users.user.firstName, 'Test');
      expect(login.fbaUser, same(auth.newUser));
      expect(login.signedInWith, SignedInWith.signUp);
      expect(messages, isEmpty);
      expect(Firebase.apps, isEmpty);
    },
  );

  testWidgets('invalid signup returns false before Auth and allows retry', (
    tester,
  ) async {
    final context = await mount(tester);
    signup.emailController.text = 'invalid';
    expect(await signup.submit(context), isFalse);
    expect(auth.signupCalls, 0);
    expect(users.user.email, isEmpty);
    signup.emailController.text = 'test@example.test';
    expect(await signup.submit(context), isTrue);
    expect(auth.signupCalls, 1);
  });

  testWidgets('signup prevents duplicate requests while Auth is pending', (
    tester,
  ) async {
    final context = await mount(tester);
    auth.pendingSignup = Completer<UserCredential>();
    final pending = signup.submit(context);
    await tester.pump();
    expect(await signup.submit(context), isFalse);
    expect(auth.signupCalls, 1);
    auth.pendingSignup!.complete(_Credential(auth.newUser));
    expect(await pending, isTrue);
  });

  final signupErrors = <String, String>{
    'email-already-in-use': MessageTranslationConstants.emailUsed,
    'invalid-email': MessageTranslationConstants.invalidEmailFormat,
    'weak-password': AuthTranslationConstants.signUpWeakPassword,
    'operation-not-allowed': AuthTranslationConstants.authMethodUnavailable,
    'network-request-failed': AuthTranslationConstants.authNetworkError,
    'too-many-requests': AuthTranslationConstants.authTooManyRequests,
    'internal-error': AuthTranslationConstants.signUpFailed,
  };
  for (final error in signupErrors.entries) {
    testWidgets('signup ${error.key} gives a human message and permits retry', (
      tester,
    ) async {
      final context = await mount(tester);
      auth.signupError = FirebaseAuthException(
        code: error.key,
        message: 'private technical error',
      );
      expect(await signup.submit(context), isFalse);
      expect(messages.single, error.value.tr);
      expect(messages.single, isNot(error.value));
      expect(messages.single, isNot(contains('private technical error')));
      expect(users.user.id, isEmpty);
      expect(login.fbaUser, isNull);
      auth.signupError = null;
      expect(await signup.submit(context), isTrue);
      expect(auth.signupCalls, 2);
    });
  }

  testWidgets('unexpected signup errors are not exposed to the user', (
    tester,
  ) async {
    final context = await mount(tester);
    auth.signupError = StateError(
      'cloud_firestore/permission-denied secret detail',
    );
    expect(await signup.submit(context), isFalse);
    expect(messages.single, AuthTranslationConstants.signUpFailed.tr);
    expect(messages.single, isNot(contains('permission-denied')));
  });

  testWidgets('null Auth user does not report successful signup', (
    tester,
  ) async {
    final context = await mount(tester);
    auth.newUser = null;
    expect(await signup.submit(context), isFalse);
    expect(messages.single, AuthTranslationConstants.signUpFailed.tr);
    expect(login.fbaUser, isNull);
  });

  testWidgets(
    'reset validates locally and never initializes Firebase or Firestore',
    (tester) async {
      final context = await mount(tester);
      expect(Firebase.apps, isEmpty);
      reset.emailController.text = 'not an email';
      expect(await reset.submitForm(context), isFalse);
      expect(auth.resetCalls, 0);
      expect(confirmations, 0);
      reset.emailController.text = ' TEST@EXAMPLE.TEST ';
      expect(await reset.submitForm(context), isTrue);
      expect(auth.resetCalls, 1);
      expect(auth.email, 'test@example.test');
      expect(confirmations, 1);
      expect(messages.last, AuthTranslationConstants.passwordResetRequested.tr);
      expect(Firebase.apps, isEmpty);
    },
  );

  testWidgets(
    'reset missing account and existing account have identical outcomes',
    (tester) async {
      final context = await mount(tester);
      expect(await reset.submitForm(context), isTrue);
      final existingAccountMessage = messages.single;
      auth.resetError = FirebaseAuthException(
        code: 'user-not-found',
        message: 'private detail',
      );
      expect(await reset.submitForm(context), isTrue);
      expect(messages.last, existingAccountMessage);
      expect(messages.last, AuthTranslationConstants.passwordResetRequested.tr);
      expect(confirmations, 2);
      expect(auth.resetCalls, 2);
    },
  );

  testWidgets(
    'reset prevents parallel submissions and permits a later request',
    (tester) async {
      final context = await mount(tester);
      auth.pendingReset = Completer<void>();
      final pending = reset.submitForm(context);
      expect(reset.isButtonDisabled.value, isTrue);
      expect(await reset.submitForm(context), isFalse);
      expect(auth.resetCalls, 1);
      auth.pendingReset!.complete();
      expect(await pending, isTrue);
      expect(reset.isButtonDisabled.value, isFalse);
      expect(await reset.submitForm(context), isTrue);
      expect(auth.resetCalls, 2);
    },
  );

  testWidgets('reset returns to login with a neutral confirmation in the UI', (
    tester,
  ) async {
    final controller = ForgotPasswordController(firebaseAuth: auth);
    addTearDown(controller.onClose);
    controller.emailController.text = 'test@example.test';
    await tester.pumpWidget(
      SintMaterialApp(
        locale: const Locale('es'),
        translations: _Translations(),
        initialRoute: AppRouteConstants.forgotPassword,
        sintPages: [
          SintPage(
            name: AppRouteConstants.forgotPassword,
            page: () => const Scaffold(body: Text('Reset form')),
          ),
          SintPage(
            name: AppRouteConstants.login,
            page: () => const Scaffold(body: Text('Login form')),
          ),
        ],
      ),
    );
    await tester.pumpAndSettle();
    final context = tester.element(find.text('Reset form'));
    expect(await controller.submitForm(context), isTrue);
    await tester.pumpAndSettle();
    expect(Sint.currentRoute, AppRouteConstants.login);
    expect(find.text('Login form'), findsOneWidget);
    expect(
      find.text(AuthTranslationConstants.passwordResetRequested.tr),
      findsOneWidget,
    );
    await tester.pump(const Duration(seconds: 4));
    await tester.pumpAndSettle();
  });

  final resetErrors = <String, String>{
    'invalid-email': MessageTranslationConstants.invalidEmailFormat,
    'network-request-failed': AuthTranslationConstants.authNetworkError,
    'too-many-requests': AuthTranslationConstants.authTooManyRequests,
    'internal-error': AuthTranslationConstants.passwordResetFailed,
  };
  for (final error in resetErrors.entries) {
    testWidgets('reset ${error.key} is translated and can be retried', (
      tester,
    ) async {
      final context = await mount(tester);
      auth.resetError = FirebaseAuthException(
        code: error.key,
        message: 'private technical detail',
      );
      expect(await reset.submitForm(context), isFalse);
      expect(messages.single, error.value.tr);
      expect(messages.single, isNot(error.value));
      expect(confirmations, 0);
      expect(reset.isButtonDisabled.value, isFalse);
      auth.resetError = null;
      expect(await reset.submitForm(context), isTrue);
      expect(confirmations, 1);
    });
  }

  testWidgets('unexpected reset error is generic, not permission-denied text', (
    tester,
  ) async {
    final context = await mount(tester);
    auth.resetError = StateError(
      'cloud_firestore/permission-denied private detail',
    );
    expect(await reset.submitForm(context), isFalse);
    expect(messages.single, AuthTranslationConstants.passwordResetFailed.tr);
    expect(confirmations, 0);
    expect(reset.isButtonDisabled.value, isFalse);
  });

  test(
    'all new notices have nonempty translations in every supported locale',
    () {
      for (final key in [
        AuthTranslationConstants.signUpFailed,
        AuthTranslationConstants.signUpWeakPassword,
        AuthTranslationConstants.authMethodUnavailable,
        AuthTranslationConstants.authNetworkError,
        AuthTranslationConstants.authTooManyRequests,
        AuthTranslationConstants.passwordResetRequested,
        AuthTranslationConstants.passwordResetFailed,
      ]) {
        for (final map in [
          AuthEsTranslations.values,
          AuthEnTranslations.values,
          AuthFrTranslations.values,
          AuthDeTranslations.values,
        ]) {
          expect(map[key], isNotNull);
          expect(map[key], isNotEmpty);
          expect(map[key], isNot(key));
        }
      }
    },
  );
}
