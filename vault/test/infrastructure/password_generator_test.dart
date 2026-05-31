import 'package:flutter_test/flutter_test.dart';
import 'package:vault/infrastructure/storage/password_generator_service_impl.dart';

void main() {
  final generator = PasswordGeneratorServiceImpl();

  group('PasswordGeneratorService', () {
    test('generates password of correct length', () {
      final p = generator.generate(length: 20);
      expect(p.length, 20);
    });

    test('contains uppercase when enabled', () {
      final p = generator.generate(length: 32, uppercase: true);
      expect(p, matches(RegExp(r'[A-Z]')));
    });

    test('contains numbers when enabled', () {
      final p = generator.generate(length: 32, numbers: true);
      expect(p, matches(RegExp(r'[0-9]')));
    });

    test('contains symbols when enabled', () {
      final p = generator.generate(length: 32, symbols: true);
      expect(p, matches(RegExp(r'[!@#\$%^&*()\-_=+\[\]{}|;:,.<>?]')));
    });

    test('two calls produce different passwords', () {
      final p1 = generator.generate();
      final p2 = generator.generate();
      expect(p1, isNot(p2));
    });

    test('no uppercase when disabled', () {
      for (int i = 0; i < 20; i++) {
        final p = generator.generate(
            length: 32, uppercase: false, numbers: false, symbols: false);
        expect(p, isNot(matches(RegExp(r'[A-Z0-9!@#]'))));
      }
    });
  });
}
