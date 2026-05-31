class AppConstants {
  AppConstants._();

  static const String appName = 'Vault';

  // Argon2id parameters
  static const int argon2Memory = 65536; // 64 MB
  static const int argon2Iterations = 3;
  static const int argon2Parallelism = 4;
  static const int argon2HashLength = 32;

  // AES-256-GCM
  static const int aesKeyLength = 32; // bytes
  static const int aesIvLength = 12;  // bytes (96-bit nonce)

  // UX timers
  static const Duration clipboardClearDelay = Duration(seconds: 30);
  static const Duration passwordHideDelay = Duration(seconds: 10);

  // Secure storage keys
  static const String keyArgon2Salt = 'argon2_salt';
  static const String keyMasterHash = 'master_hash';
  static const String keyBiometricEnabled = 'biometric_enabled';
}
