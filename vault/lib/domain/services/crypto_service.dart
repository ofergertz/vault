abstract interface class CryptoService {
  /// Derives a 32-byte key from [password] using Argon2id.
  /// [salt] is a base64-encoded random salt (16 bytes).
  Future<List<int>> deriveKey(String password, String salt);

  /// Generates a cryptographically random base64-encoded salt.
  String generateSalt();

  /// Encrypts [plaintext] using AES-256-GCM with [key].
  /// Returns a record with (ciphertext: base64, iv: base64).
  Future<({String ciphertext, String iv})> encrypt(
      List<int> key, String plaintext);

  /// Decrypts [ciphertext] using AES-256-GCM with [key] and [iv].
  /// Throws [CryptoException] if authentication tag is invalid.
  Future<String> decrypt(List<int> key, String ciphertext, String iv);

  /// Hashes [password] for storage verification (SHA-256 of derived key).
  Future<String> hashForVerification(List<int> derivedKey);
}
