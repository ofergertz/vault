sealed class AuthState {
  const AuthState();
}

/// App is loading (checking if setup is complete)
class AuthLoading extends AuthState {
  const AuthLoading();
}

/// First launch — no master password set
class AuthSetupRequired extends AuthState {
  const AuthSetupRequired();
}

/// Vault is locked — user must authenticate
class AuthLocked extends AuthState {
  final bool biometricAvailable;
  const AuthLocked({required this.biometricAvailable});
}

/// Vault is unlocked — derived key is in memory
class AuthUnlocked extends AuthState {
  final List<int> key;
  const AuthUnlocked({required this.key});
}

/// An error occurred during auth
class AuthError extends AuthState {
  final String message;
  const AuthError(this.message);
}
