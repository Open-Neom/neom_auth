import 'package:flutter_test/flutter_test.dart';
import 'package:neom_auth/data/translations/auth_en_translations.dart';
import 'package:neom_auth/data/translations/auth_es_translations.dart';
import 'package:neom_auth/data/translations/auth_de_translations.dart';
import 'package:neom_auth/data/translations/auth_fr_translations.dart';

void main() {
  final en = AuthEnTranslations.values;
  final es = AuthEsTranslations.values;
  final de = AuthDeTranslations.values;
  final fr = AuthFrTranslations.values;

  group('Auth translation maps - parity', () {
    test('all languages have the same key set as English', () {
      expect(es.keys.toSet(), en.keys.toSet(),
          reason: 'Spanish keys diverge from English');
      expect(de.keys.toSet(), en.keys.toSet(),
          reason: 'German keys diverge from English');
      expect(fr.keys.toSet(), en.keys.toSet(),
          reason: 'French keys diverge from English');
    });

    test('no translation map has empty values', () {
      for (final entry in {'en': en, 'es': es, 'de': de, 'fr': fr}.entries) {
        for (final kv in entry.value.entries) {
          expect(kv.value.trim(), isNotEmpty,
              reason: '${entry.key}[${kv.key}] is empty');
        }
      }
    });

    test('no translation map has duplicate keys (Map invariant)', () {
      // Sanity: Map cannot have duplicates by language. Verify keys count.
      expect(en.length, en.keys.toSet().length);
    });

    test('keys do not contain whitespace', () {
      for (final k in en.keys) {
        expect(k.contains(' '), isFalse, reason: 'Key "$k" contains space');
      }
    });
  });
}
