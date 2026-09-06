import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:neom_auth/data/translations/auth_de_translations.dart';
import 'package:neom_auth/data/translations/auth_en_translations.dart';
import 'package:neom_auth/data/translations/auth_es_translations.dart';
import 'package:neom_auth/data/translations/auth_fr_translations.dart';
import 'package:neom_auth/ui/widgets/account_load_error_notice.dart';
import 'package:neom_auth/utils/constants/auth_translation_constants.dart';
import 'package:sint/sint.dart';

const _translations = {
  'en': AuthEnTranslations.values,
  'es': AuthEsTranslations.values,
  'de': AuthDeTranslations.values,
  'fr': AuthFrTranslations.values,
};

Widget _host({
  required VoidCallback onRetry,
  double width = 308,
  double textScale = 1,
}) => MaterialApp(
  home: Scaffold(
    backgroundColor: Colors.black,
    body: MediaQuery(
      data: MediaQueryData(textScaler: TextScaler.linear(textScale)),
      child: SingleChildScrollView(
        child: Center(
          child: SizedBox(
            width: width,
            child: AccountLoadErrorNotice(onRetry: onRetry),
          ),
        ),
      ),
    ),
  ),
);

void main() {
  setUp(() {
    Sint.clearTranslations();
    Sint.addTranslations(_translations);
    Sint.locale = const Locale('es');
    Sint.fallbackLocale = const Locale('en');
  });

  tearDown(() {
    Sint.clearTranslations();
    Sint.locale = null;
    Sint.fallbackLocale = null;
  });

  for (final locale in _translations.keys) {
    testWidgets('renders translated account recovery notice in $locale', (
      tester,
    ) async {
      Sint.locale = Locale(locale);
      await tester.pumpWidget(_host(onRetry: () {}));

      final values = _translations[locale]!;
      for (final key in [
        AuthTranslationConstants.accountLoadErrorTitle,
        AuthTranslationConstants.accountLoadErrorMessage,
        AuthTranslationConstants.retryAccountLoad,
      ]) {
        expect(find.text(values[key]!), findsOneWidget);
        expect(find.text(key), findsNothing);
      }
      expect(tester.takeException(), isNull);
    });

    testWidgets('supports narrow mobile width and enlarged text in $locale', (
      tester,
    ) async {
      Sint.locale = Locale(locale);
      await tester.pumpWidget(_host(onRetry: () {}, width: 240, textScale: 2));
      await tester.ensureVisible(find.byType(OutlinedButton));
      await tester.pumpAndSettle();

      expect(find.byType(OutlinedButton).hitTestable(), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('retry invokes the supplied recovery action once', (
    tester,
  ) async {
    var retryCalls = 0;
    await tester.pumpWidget(_host(onRetry: () => retryCalls++));

    await tester.tap(find.byType(OutlinedButton));

    expect(retryCalls, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('notice persists and announces its recovery message', (
    tester,
  ) async {
    await tester.pumpWidget(_host(onRetry: () {}));
    await tester.pump(const Duration(seconds: 15));

    expect(find.byType(AccountLoadErrorNotice), findsOneWidget);
    expect(
      find.text(
        AuthEsTranslations.values[AuthTranslationConstants
            .accountLoadErrorMessage]!,
      ),
      findsOneWidget,
    );
    final semantics = tester.widget<Semantics>(
      find.descendant(
        of: find.byType(AccountLoadErrorNotice),
        matching: find.byWidgetPredicate(
          (widget) =>
              widget is Semantics && widget.properties.liveRegion == true,
        ),
      ),
    );
    expect(semantics.properties.liveRegion, isTrue);
  });
}
