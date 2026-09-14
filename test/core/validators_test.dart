import 'package:flutter_test/flutter_test.dart';
import 'package:totoitaliano/core/utils/validators.dart';

void main() {
  group('Validators.email', () {
    test('accetta un indirizzo valido', () {
      expect(Validators.email('mario.rossi@example.com'), isNull);
    });

    test('rifiuta un indirizzo senza dominio', () {
      expect(Validators.email('mario.rossi@'), isNotNull);
    });

    test('rifiuta un valore vuoto', () {
      expect(Validators.email(''), isNotNull);
    });
  });

  group('Validators.username', () {
    test('accetta username valido', () {
      expect(Validators.username('mario_rossi99'), isNull);
    });

    test('rifiuta username troppo corto', () {
      expect(Validators.username('ab'), isNotNull);
    });

    test('rifiuta caratteri non ammessi', () {
      expect(Validators.username('mario rossi!'), isNotNull);
    });
  });

  group('Validators.password', () {
    test('accetta password conforme', () {
      expect(Validators.password('Password1'), isNull);
    });

    test('rifiuta password troppo corta', () {
      expect(Validators.password('Pw1'), isNotNull);
    });

    test('rifiuta password senza maiuscola', () {
      expect(Validators.password('password1'), isNotNull);
    });

    test('rifiuta password senza numero', () {
      expect(Validators.password('Password'), isNotNull);
    });
  });

  group('Validators.confirmPassword', () {
    test('accetta se coincide', () {
      expect(Validators.confirmPassword('Password1', 'Password1'), isNull);
    });

    test('rifiuta se non coincide', () {
      expect(Validators.confirmPassword('Password2', 'Password1'), isNotNull);
    });
  });

  group('Validators.inviteCode', () {
    test('accetta un codice lega valido', () {
      expect(Validators.inviteCode('TOTO-8K4P2'), isNull);
    });

    test('rifiuta un codice troppo corto', () {
      expect(Validators.inviteCode('ABC'), isNotNull);
    });
  });
}
