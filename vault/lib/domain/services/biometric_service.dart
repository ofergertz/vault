abstract interface class BiometricService {
  /// Returns true if biometric hardware is available and enrolled.
  Future<bool> isAvailable();

  /// Prompts biometric authentication with [reason] displayed to the user.
  /// Returns true on success, false on failure/cancel.
  Future<bool> authenticate(String reason);
}
