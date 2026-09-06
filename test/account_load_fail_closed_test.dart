import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart' as fba;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:neom_auth/ui/login/login_controller.dart';
import 'package:neom_core/app_config.dart';
import 'package:neom_core/data/implementations/app_hive_controller.dart';
import 'package:neom_core/domain/model/account_load_exception.dart';
import 'package:neom_core/domain/model/app_profile.dart';
import 'package:neom_core/domain/model/app_user.dart';
import 'package:neom_core/domain/use_cases/user_service.dart';
import 'package:neom_core/utils/constants/app_route_constants.dart';
import 'package:neom_core/utils/enums/auth_status.dart';
import 'package:neom_core/utils/enums/signed_in_with.dart';
import 'package:sint/sint.dart';

class _Provider extends Fake implements fba.UserInfo {
  _Provider(this.providerId, this.email);
  @override
  final String providerId;
  @override
  final String? email;
  @override
  String get uid => 'provider-id';
}

class _FirebaseUser extends Fake implements fba.User {
  _FirebaseUser({
    this.email = 'owner@example.test',
    this.providerEmail,
    this.provider = 'google.com',
  });
  @override
  final String? email;
  final String? providerEmail;
  final String provider;
  @override
  String get uid => 'auth-id';
  @override
  List<fba.UserInfo> get providerData => [
    _Provider(provider, providerEmail ?? email),
  ];
  @override
  String? get displayName => null;
  @override
  String? get photoURL => null;
}

class _Credential extends Fake implements fba.UserCredential {
  _Credential(this.user);
  @override
  final fba.User user;
}

class _Auth extends Fake implements fba.FirebaseAuth {
  _Auth(this.currentUser);
  @override
  final fba.User? currentUser;
  Completer<fba.UserCredential>? credential;
  @override
  Future<fba.UserCredential> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) => credential!.future;
}

class _UserService extends Fake implements UserService {
  bool fail = true;
  bool missing = false;
  final lookups = <String>[];
  @override
  AppUser user = AppUser();
  @override
  AppProfile profile = AppProfile();
  @override
  bool isNewUser = false;
  int firebaseFallbacks = 0;
  int createCalls = 0;

  Future<void> _load(String key) async {
    lookups.add(key);
    isNewUser = false;
    if (fail) throw const AccountLoadException();
    if (missing) {
      user = AppUser();
      isNewUser = true;
      return;
    }
    profile = AppProfile(id: 'profile', name: 'Loaded profile');
    user = AppUser(id: 'existing-account', profiles: [profile]);
  }

  @override
  Future<void> setUserByEmail(String email) => _load('email:$email');
  @override
  Future<void> setUserById(String id) => _load('id:$id');
  @override
  void getUserFromFirebase(fba.User firebaseUser) {
    firebaseFallbacks++;
    user = AppUser(id: 'new-account', email: firebaseUser.email ?? '');
  }

  @override
  Future<void> createUser() async => createCalls++;
}

class _Hive extends Fake implements AppHiveController {
  int writes = 0;
  @override
  Future<void> writeProfileInfo({bool overwrite = false}) async => writes++;
}

class _LoginController extends LoginController {
  _LoginController(_UserService service, _Auth auth)
    : super(userService: service, firebaseAuth: auth);
  int introCalls = 0;
  @override
  void gotoIntroPage() => introCalls++;
}

void main() {
  late _UserService service;
  late _Auth auth;
  late _LoginController controller;

  setUp(() {
    Sint.reset();
    AppConfig.instance.isGuestMode = true;
    service = _UserService();
    auth = _Auth(_FirebaseUser());
    controller = _LoginController(service, auth);
  });

  tearDown(() {
    Sint.reset();
    AppConfig.instance.isGuestMode = true;
  });

  Future<void> mount(
    WidgetTester tester, {
    String route = AppRouteConstants.login,
  }) async {
    await tester.pumpWidget(
      SintMaterialApp(
        initialRoute: route,
        sintPages: [
          SintPage(
            name: AppRouteConstants.login,
            page: () => const Scaffold(body: Text('Login')),
          ),
          SintPage(
            name: AppRouteConstants.root,
            page: () => const Scaffold(body: Text('Root')),
          ),
        ],
      ),
    );
    await tester.pumpAndSettle();
  }

  for (final provider in [
    SignedInWith.google,
    SignedInWith.email,
    SignedInWith.apple,
    SignedInWith.signUp,
  ]) {
    testWidgets(
      '$provider lookup failure stays at login, never onboarding or creation',
      (tester) async {
        await mount(tester);
        controller.signedInWith = provider;
        await controller.handleAuthChanged(auth.currentUser);
        await tester.pumpAndSettle();
        expect(controller.authStatus.value, AuthStatus.notLoggedIn);
        expect(controller.hasAccountLoadError.value, isTrue);
        expect(controller.isLoading.value, isFalse);
        expect(controller.introCalls, 0);
        expect(service.firebaseFallbacks, 0);
        expect(service.createCalls, 0);
        expect(AppConfig.instance.isGuestMode, isTrue);
        expect(Sint.currentRoute, AppRouteConstants.login);
      },
    );
  }

  testWidgets('session restoration failure navigates to recoverable login', (
    tester,
  ) async {
    await mount(tester, route: AppRouteConstants.root);
    await controller.handleAuthChanged(auth.currentUser);
    await tester.pumpAndSettle();
    expect(Sint.currentRoute, AppRouteConstants.login);
    expect(controller.hasAccountLoadError.value, isTrue);
    expect(controller.introCalls, 0);
  });

  testWidgets('retry loads the same authenticated account and clears failure', (
    tester,
  ) async {
    await mount(tester);
    final hive = _Hive();
    Sint.put<AppHiveController>(hive, permanent: true);
    controller.signedInWith = SignedInWith.google;
    await controller.handleAuthChanged(auth.currentUser);
    await tester.pumpAndSettle();
    service.fail = false;
    await controller.retryAccountLoad();
    await tester.pumpAndSettle();
    expect(service.lookups, [
      'email:owner@example.test',
      'email:owner@example.test',
    ]);
    expect(controller.hasAccountLoadError.value, isFalse);
    expect(controller.authStatus.value, AuthStatus.loggedIn);
    expect(controller.introCalls, 0);
    expect(hive.writes, 1);
    expect(Sint.currentRoute, AppRouteConstants.root);
  });

  testWidgets('only confirmed absence starts a new OAuth account', (
    tester,
  ) async {
    await mount(tester);
    service
      ..fail = false
      ..missing = true;
    controller.signedInWith = SignedInWith.google;
    await controller.handleAuthChanged(auth.currentUser);
    expect(controller.introCalls, 1);
    expect(service.firebaseFallbacks, 1);
    expect(controller.hasAccountLoadError.value, isFalse);
  });

  testWidgets(
    'confirmed new signup preserves the matching draft and opens intro once',
    (tester) async {
      await mount(tester);
      final draft = AppUser(
        id: 'owner@example.test',
        email: 'owner@example.test',
        name: 'Signup draft',
      );
      service
        ..fail = false
        ..missing = true
        ..user = draft;
      controller.signedInWith = SignedInWith.signUp;
      await controller.handleAuthChanged(auth.currentUser);
      expect(identical(service.user, draft), isTrue);
      expect(controller.introCalls, 1);
      expect(service.firebaseFallbacks, 0);
    },
  );

  testWidgets('query uses Auth token email, not a different provider email', (
    tester,
  ) async {
    await mount(tester);
    await controller.handleAuthChanged(
      _FirebaseUser(providerEmail: 'different@example.test'),
    );
    expect(service.lookups, ['email:owner@example.test']);
  });

  testWidgets('identity without email fails closed through the ID lookup', (
    tester,
  ) async {
    await mount(tester);
    await controller.handleAuthChanged(
      _FirebaseUser(email: null, provider: 'password'),
    );
    await tester.pumpAndSettle();
    expect(service.lookups, ['id:provider-id']);
    expect(controller.hasAccountLoadError.value, isTrue);
    expect(controller.introCalls, 0);
  });

  testWidgets(
    'late credential response cannot overwrite failed account status',
    (tester) async {
      await mount(tester);
      auth.credential = Completer<fba.UserCredential>();
      final signingIn = controller.emailLogin();
      await controller.handleAuthChanged(auth.currentUser);
      auth.credential!.complete(_Credential(auth.currentUser!));
      await signingIn;
      expect(controller.authStatus.value, AuthStatus.notLoggedIn);
      expect(controller.hasAccountLoadError.value, isTrue);
      expect(controller.introCalls, 0);
    },
  );
}
