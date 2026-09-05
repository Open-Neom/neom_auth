import 'package:flutter_test/flutter_test.dart';
import 'package:neom_auth/ui/signup/signup_controller.dart';

void main() {
  test('signup keeps the password outside the persistable AppUser model', () {
    final user = SignUpController.buildUserFromSignUp(
      homeTown: 'Algún lugar del universo',
      username: '  Cuenta Prueba  ',
      firstName: '  Prueba ',
      lastName: ' EMXI  ',
      email: ' TEST.USER@EXAMPLE.TEST ',
    );

    expect(user.id, 'test.user@example.test');
    expect(user.email, 'test.user@example.test');
    expect(user.name, 'Cuenta Prueba');
    expect(user.firstName, 'Prueba');
    expect(user.lastName, 'EMXI');
    // Legacy field remains readable only while historical documents migrate.
    // ignore: deprecated_member_use
    expect(user.password, isEmpty);
    expect(user.toJSON(), isNot(contains('password')));
  });
}
