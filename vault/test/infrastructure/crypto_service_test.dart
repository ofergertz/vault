import 'package:flutter_test/flutter_test.dart';
import 'package:vault/core/errors.dart';
import 'package:vault/infrastructure/crypto/crypto_service_impl.dart';

void main() {
  final crypto = CryptoServiceImpl();

  group('CryptoService', () {
    test('generateSalt returns non-empty base64 string', () {
      final salt = crypto.generateSalt();
      expect(salt, isNotEmpty);
      expect(salt.length, greaterThan(10));
    });

    test('two salts are different', () {
      final s1 = crypto.generateSalt();
      final s2 = crypto.generateSalt();
      expect(s1, isNot(s2));
    });

    test('deriveKey is deterministic with same password and salt', () async {
      final salt = crypto.generateSalt();
      final k1 = await crypto.deriveKey('password123', salt);
      final k2 = await crypto.deriveKey('password123', salt);
      expect(k1, k2);
    });

    test('deriveKey differs with different password', () async {
      final salt = crypto.generateSalt();
      final k1 = await crypto.deriveKey('password1', salt);
      final k2 = await crypto.deriveKey('password2', salt);
      expect(k1, isNot(k2));
    });

    test('encrypt/decrypt roundtrip', () async {
      final salt = crypto.generateSalt();
      final key = await crypto.deriveKey('masterpass', salt);
      const plaintext = 'MySecretPassword!123';

      final (:ciphertext, :iv) = await crypto.encrypt(key, plaintext);
      final decrypted = await crypto.decrypt(key, ciphertext, iv);

      expect(decrypted, plaintext);
    });

    test('encrypt produces different ciphertext each call (random IV)', () async {
      final salt = crypto.generateSalt();
      final key = await crypto.deriveKey('masterpass', salt);
      const plaintext = 'SamePassword';

      final r1 = await crypto.encrypt(key, plaintext);
      final r2 = await crypto.encrypt(key, plaintext);

      expect(r1.ciphertext, isNot(r2.ciphertext));
      expect(r1.iv, isNot(r2.iv));
    });

    test('decrypt throws CryptoException with wrong key', () async {
      final salt = crypto.generateSalt();
      final key1 = await crypto.deriveKey('correct', salt);
      final key2 = await crypto.deriveKey('wrong', salt);

      final (:ciphertext, :iv) = await crypto.encrypt(key1, 'secret');

      expect(
        () => crypto.decrypt(key2, ciphertext, iv),
        throwsA(isA<CryptoException>()),
      );
    });

    test('hashForVerification is consistent', () async {
      final salt = crypto.generateSalt();
      final key = await crypto.deriveKey('pass', salt);
      final h1 = await crypto.hashForVerification(key);
      final h2 = await crypto.hashForVerification(key);
      expect(h1, h2);
    });
  });
}
