# Vault 🔐

A simple, fully offline password manager for Android and iOS.

## Features
- 🔒 AES-256-GCM encryption per entry
- 🧠 Argon2id master password derivation
- 👆 Biometric unlock (Face ID / fingerprint)
- 🔑 Built-in strong password generator
- 🔍 Search by app name
- 📱 Offline only — no cloud, no server

## Project Structure

```
lib/
  main.dart                   # Entry point
  app.dart                    # MaterialApp + router
  core/                       # Constants + error types
  domain/                     # Models, interfaces (pure Dart)
  application/                # Riverpod controllers + states
  infrastructure/             # Implementations (crypto, DB, biometric)
  presentation/               # Screens + widgets
test/
  domain/                     # Model tests
  infrastructure/             # Crypto + generator tests
  application/                # Controller tests (TODO)
```

## Getting Started

```bash
flutter pub get
flutter run
```

## Running Tests

```bash
flutter test
```

## Architecture

Clean Architecture with 4 layers:
- **Presentation** — Flutter screens (Riverpod consumers)
- **Application** — StateNotifiers (AuthController, VaultController)
- **Domain** — Pure Dart models and interfaces
- **Infrastructure** — SQLite, secure storage, crypto implementations

## Security Notes
- Passwords stored encrypted in SQLite (AES-256-GCM, random IV per entry)
- Derived key lives in memory only — cleared on app lock
- Salt + hash stored in iOS Keychain / Android Keystore
- Clipboard auto-cleared after 30 seconds
