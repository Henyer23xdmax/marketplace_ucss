import 'package:flutter_test/flutter_test.dart';
import 'package:marketplace_ucss_ios/screens/auth/auth_widgets.dart';

void main() {
  group('scorePassword (fuerza de contraseña)', () {
    test('contraseña vacía o muy corta da 0', () {
      expect(scorePassword(''), 0);
      expect(scorePassword('abc'), 0);
    });

    test('6 caracteres ya da 1 punto', () {
      expect(scorePassword('abcdef'), 1);
    });

    test('10 caracteres da 2 puntos', () {
      expect(scorePassword('abcdefghij'), 2);
    });

    test('mayúsculas y minúsculas suman un punto', () {
      // 10+ chars = 2, mas mayus/minus = 3
      expect(scorePassword('abcdefghIJ'), 3);
    });

    test('dígitos o símbolos suman el último punto', () {
      // 10+ caracteres = 2 puntos. Sin mayúscula+minúscula combinadas, un
      // símbolo o dígito solo aporta el tercero.
      expect(scorePassword('abcdefghij12'), 3);
      expect(scorePassword('abcdefghij!@'), 3);
      expect(scorePassword('Abcdefghij12'), 4);
    });

    test('el máximo es 4', () {
      expect(scorePassword('Abcdefghij1!'), 4);
    });

    test('nunca excede 4', () {
      expect(scorePassword(r'A1!b2@c3#d4$e5%f6^'), lessThanOrEqualTo(4));
    });
  });
}
