import 'package:flutter_test/flutter_test.dart';
import 'package:neom_core/utils/validator.dart';
import 'package:neom_core/utils/enums/validation_error.dart';
import 'package:neom_core/utils/constants/core_constants.dart';

void main() {
  group('Validator.validatePassword', () {
    test('empty password returns pleaseEnterPassword', () {
      expect(Validator.validatePassword('', ''),
          ValidationError.pleaseEnterPassword.name);
    });

    test('1-char password too short', () {
      expect(Validator.validatePassword('a', 'a'),
          ValidationError.passwordTooShort.name);
    });

    test('exactly minimum length passes if matches', () {
      final pw = 'a' * CoreConstants.passwordMinimumLength;
      expect(Validator.validatePassword(pw, pw), '');
    });

    test('one below minimum length too short', () {
      final pw = 'a' * (CoreConstants.passwordMinimumLength - 1);
      expect(Validator.validatePassword(pw, pw),
          ValidationError.passwordTooShort.name);
    });

    test('one above maximum length too long', () {
      final pw = 'a' * (CoreConstants.passwordMaximumLength + 1);
      expect(Validator.validatePassword(pw, pw),
          ValidationError.passwordTooLong.name);
    });

    test('exactly maximum length passes', () {
      final pw = 'a' * CoreConstants.passwordMaximumLength;
      expect(Validator.validatePassword(pw, pw), '');
    });

    test('mismatch returns passwordsNotMatch', () {
      expect(Validator.validatePassword('abcdef', 'ABCDEF'),
          ValidationError.passwordsNotMatch.name);
    });

    test('extreme long password rejected', () {
      final pw = 'x' * 10000;
      expect(Validator.validatePassword(pw, pw),
          ValidationError.passwordTooLong.name);
    });

    test('unicode password counted by code units, accepted at min length', () {
      final pw = 'áéíóúñ'; // 6 chars
      expect(Validator.validatePassword(pw, pw), '');
    });
  });

  group('Validator.validateName', () {
    test('empty returns pleaseEnterFullName', () {
      expect(Validator.validateName(''),
          ValidationError.pleaseEnterFullName.name);
    });

    test('contains digit (any) returns invalidName', () {
      // _isNumeric returns true if ANY char is numeric
      expect(Validator.validateName('John2'),
          ValidationError.invalidName.name);
    });

    test('one char too short', () {
      expect(Validator.validateName('A'),
          ValidationError.usernameTooShort.name);
    });

    test('exactly minimum length valid', () {
      final n = 'A' * CoreConstants.nameMinimumLength;
      expect(Validator.validateName(n), '');
    });

    test('above maximum length too long', () {
      final n = 'A' * (CoreConstants.usernameMaximumLength + 1);
      expect(Validator.validateName(n),
          ValidationError.usernameTooLong.name);
    });

    test('valid name returns empty', () {
      expect(Validator.validateName('Alice'), '');
    });
  });

  group('Validator.validateUsername', () {
    test('empty returns pleaseEnterUsername', () {
      expect(Validator.validateUsername(''),
          ValidationError.pleaseEnterUsername.name);
    });

    test('numeric only returns invalidUsername', () {
      expect(Validator.validateUsername('12345'),
          ValidationError.invalidUsername.name);
    });

    test('too short flagged', () {
      final n = 'a' * (CoreConstants.usernameMinimumLength - 1);
      expect(Validator.validateUsername(n),
          ValidationError.usernameTooShort.name);
    });

    test('alphanumeric mix valid', () {
      expect(Validator.validateUsername('user1'), '');
    });

    test('exactly minimum length valid', () {
      final n = 'a' * CoreConstants.usernameMinimumLength;
      expect(Validator.validateUsername(n), '');
    });

    test('exactly maximum length valid', () {
      final n = 'a' * CoreConstants.usernameMaximumLength;
      expect(Validator.validateUsername(n), '');
    });

    test('one above maximum length too long', () {
      final n = 'a' * (CoreConstants.usernameMaximumLength + 1);
      expect(Validator.validateUsername(n),
          ValidationError.usernameTooLong.name);
    });
  });
}
