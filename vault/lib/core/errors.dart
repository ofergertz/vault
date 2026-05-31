/// Base class for all Vault exceptions
abstract class VaultException implements Exception {
  final String message;
  const VaultException(this.message);

  @override
  String toString() => '$runtimeType: $message';
}

/// Thrown when encryption or decryption fails
class CryptoException extends VaultException {
  const CryptoException(super.message);
}

/// Thrown when master password verification fails
class AuthException extends VaultException {
  const AuthException(super.message);
}

/// Thrown on database or secure storage errors
class StorageException extends VaultException {
  const StorageException(super.message);
}

/// Thrown when biometric auth is unavailable or fails
class BiometricException extends VaultException {
  const BiometricException(super.message);
}
