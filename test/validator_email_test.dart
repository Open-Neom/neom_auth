import 'package:flutter_test/flutter_test.dart';
import 'package:neom_core/utils/validator.dart';
import 'package:neom_core/utils/enums/validation_error.dart';

void main() {
  group('Validator.validateEmail - basic cases', () {
    test('empty returns pleaseEnterEmail', () {
      expect(Validator.validateEmail(''),
          ValidationError.pleaseEnterEmail.name);
    });

    test('simple valid email returns empty', () {
      expect(Validator.validateEmail('user@example.com'), '');
    });

    test('uppercase still valid', () {
      expect(Validator.validateEmail('USER@EXAMPLE.COM'), '');
    });

    test('plus tag valid', () {
      expect(Validator.validateEmail('user+tag@example.com'), '');
    });

    test('subdomain valid', () {
      expect(Validator.validateEmail('user@mail.example.co.uk'), '');
    });
  });

  group('Validator.validateEmail - invalid edge cases', () {
    test('missing @ invalid', () {
      expect(Validator.validateEmail('userexample.com'),
          ValidationError.invalidEmailFormat.name);
    });

    test('missing domain invalid', () {
      expect(Validator.validateEmail('user@'),
          ValidationError.invalidEmailFormat.name);
    });

    test('missing local part invalid', () {
      expect(Validator.validateEmail('@example.com'),
          ValidationError.invalidEmailFormat.name);
    });

    test('whitespace inside invalid', () {
      expect(Validator.validateEmail('us er@example.com'),
          ValidationError.invalidEmailFormat.name);
    });

    test('TLD too short (1 char) invalid per pattern', () {
      // Pattern requires {2,}
      expect(Validator.validateEmail('user@example.c'),
          ValidationError.invalidEmailFormat.name);
    });

    test('double @ invalid', () {
      expect(Validator.validateEmail('user@@example.com'),
          ValidationError.invalidEmailFormat.name);
    });

    test('trailing dot in domain invalid per pattern', () {
      expect(Validator.validateEmail('user@example.com.'),
          ValidationError.invalidEmailFormat.name);
    });

    test('IP literal in brackets is accepted', () {
      expect(Validator.validateEmail('user@[192.168.1.1]'), '');
    });
  });

  group('Validator.isEmail boolean variant agrees with validateEmail', () {
    final cases = {
      'a@b.co': true,
      'a@b.c': false,
      '': false,
      'plain': false,
      'a@b': false,
    };
    cases.forEach((input, expected) {
      test('isEmail("$input") == $expected', () {
        expect(Validator.isEmail(input), expected);
      });
    });
  });
}
