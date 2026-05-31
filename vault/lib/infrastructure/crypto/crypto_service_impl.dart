import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';

import '../../core/constants.dart';
import '../../core/errors.dart';
import '../../domain/services/crypto_service.dart';

class CryptoServiceImpl implements CryptoService {
  final _aesGcm = AesGcm.with256bits();

  @override
  String generateSalt() {
    final rng = Random.secure();
    final bytes = List<int>.generate(16, (_) => rng.nextInt(256));
    return base64.encode(bytes);
  }

  @override
  Future<List<int>> deriveKey(String password, String salt) async {
    final saltBytes = base64.decode(salt);
    final passwordBytes = utf8.encode(password);

    // Argon2id via cryptography package
    final algorithm = Argon2id(
      memory: AppConstants.argon2Memory,
      iterations: AppConstants.argon2Iterations,
      parallelism: AppConstants.argon2Parallelism,
      hashLength: AppConstants.argon2HashLength,
    );

    final secretKey = await algorithm.deriveKey(
      secretKey: SecretKey(passwordBytes),
      nonce: saltBytes,
    );

    return secretKey.extractBytes();
  }

  @override
  Future<({String ciphertext, String iv})> encrypt(
      List<int> key, String plaintext) async {
    final secretKey = SecretKey(key);
    final nonce = _aesGcm.newNonce();

    final secretBox = await _aesGcm.encrypt(
      utf8.encode(plaintext),
      secretKey: secretKey,
      nonce: nonce,
    );

    return (
      ciphertext: base64.encode(secretBox.cipherText + secretBox.mac.bytes),
      iv: base64.encode(nonce),
    );
  }

  @override
  Future<String> decrypt(
      List<int> key, String ciphertext, String iv) async {
    try {
      final secretKey = SecretKey(key);
      final nonce = base64.decode(iv);
      final ciphertextBytes = base64.decode(ciphertext);

      // Last 16 bytes are the GCM auth tag
      final macBytes = ciphertextBytes.sublist(ciphertextBytes.length - 16);
      final encryptedBytes =
          ciphertextBytes.sublist(0, ciphertextBytes.length - 16);

      final secretBox = SecretBox(
        encryptedBytes,
        nonce: nonce,
        mac: Mac(macBytes),
      );

      final plaintext = await _aesGcm.decrypt(secretBox, secretKey: secretKey);
      return utf8.decode(plaintext);
    } catch (e) {
      throw const CryptoException('Decryption failed: invalid key or tampered data');
    }
  }

  @override
  Future<String> hashForVerification(List<int> derivedKey) async {
    final algorithm = Sha256();
    final hash = await algorithm.hash(derivedKey);
    return base64.encode(hash.bytes);
  }
}
