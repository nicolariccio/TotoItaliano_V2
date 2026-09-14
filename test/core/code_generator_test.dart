import 'package:flutter_test/flutter_test.dart';
import 'package:totoitaliano/core/utils/code_generator.dart';

void main() {
  group('CodeGenerator.referralCode', () {
    test('usa il seed come prefisso quando fornito', () {
      final code = CodeGenerator.referralCode(seed: 'mario');
      expect(code.startsWith('MARIO'), isTrue);
      expect(code.length, 9); // 'mario' (5) + 4 caratteri casuali
    });

    test('tronca i seed più lunghi di 6 caratteri', () {
      final code = CodeGenerator.referralCode(seed: 'mariorossi');
      expect(code.startsWith('MARIOR'), isTrue);
      expect(code.length, 10);
    });

    test('genera comunque un codice senza seed', () {
      final code = CodeGenerator.referralCode();
      expect(code.length, 10);
      expect(RegExp(r'^[A-Z0-9]+$').hasMatch(code), isTrue);
    });

    test('ignora caratteri non alfanumerici nel seed', () {
      final code = CodeGenerator.referralCode(seed: 'mario!!rossi');
      expect(code.startsWith('MARIOR'), isTrue);
    });
  });

  group('CodeGenerator.leagueInviteCode', () {
    test('ha il formato TOTO-XXXXX', () {
      final code = CodeGenerator.leagueInviteCode();
      expect(RegExp(r'^TOTO-[A-Z0-9]{5}$').hasMatch(code), isTrue);
    });

    test('genera codici diversi tra loro', () {
      final codes = {for (var i = 0; i < 20; i++) CodeGenerator.leagueInviteCode()};
      expect(codes.length, greaterThan(1));
    });
  });
}
