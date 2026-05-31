# Vault — Architecture Document

## Overview
A simple, fully offline mobile password manager.
Store passwords for apps on your phone — no memory required.

**Platform:** Flutter (Android + iOS — single codebase)
**Backend:** None — all data stays on device
**App Name:** Vault

---

## Tech Stack

| Concern | Library |
|---|---|
| Framework | Flutter (Dart) |
| Encryption | AES-256-GCM |
| Key Derivation | Argon2id |
| Secure Storage | flutter_secure_storage (iOS Keychain / Android Keystore) |
| Database | sqflite (SQLite) |
| State Management | Riverpod |
| Navigation | go_router (with auth guards) |
| Biometrics | local_auth |

---

## Screens

1. **Unlock** — master password entry + biometric unlock
2. **Vault List** — searchable list of all saved entries
3. **Entry Detail** — view / copy a specific password
4. **Add / Edit** — add or edit an entry (with password generator)

---

## Layer Architecture

```
Presentation  →  Unlock, VaultList, EntryDetail, AddEdit screens
     ↓
Application   →  AuthController, VaultController
     ↓
Domain        →  CryptoService, BiometricService, PasswordGeneratorService, VaultRepository (interface)
     ↓
Infrastructure →  SecureStorageService, SqliteVaultRepository
```

---

## Data Model

```dart
class VaultEntry {
  String id;           // UUID
  String appName;      // "Netflix"
  String username;     // "user@email.com"
  String encryptedPassword; // AES-256-GCM ciphertext (base64)
  String iv;           // Random 12-byte IV per entry (base64)
  DateTime createdAt;
  DateTime updatedAt;
}
```

---

## Security Model

### Master Password
- User sets a master password on first launch
- Passed through **Argon2id** (64MB memory, 3 iterations, 4 parallelism) → ~1s on mobile
- Salt + hash stored in **Keychain/Keystore** (hardware-backed)
- The derived key lives **only in memory** — never written to disk
- When app closes → key is cleared from memory
- When app reopens → user re-enters master password → key re-derived

### Password Encryption
- Each entry encrypted with **AES-256-GCM**
- Random 12-byte IV generated per entry (never reused)
- Ciphertext + IV stored in SQLite
- Auth tag built into GCM — tamper-proof

### Persistence
✅ **Passwords are stored permanently** in SQLite (encrypted)
✅ They survive app close, restart, and phone reboot
✅ Only the in-memory key is cleared on exit — NOT the passwords

### Biometric Auth
- Uses `local_auth` (Face ID / fingerprint)
- Available after first successful master password unlock
- Biometric = convenience unlock only; master password is always the fallback
- Biometric preference stored in flutter_secure_storage

### Additional Protections
- Clipboard auto-cleared after 30 seconds
- Password hidden in UI by default (●●●●●)
- Auto-hide password after 10 seconds of viewing

---

## Key Flows

### First Launch
1. Show setup screen
2. User sets master password
3. Argon2id derivation → store salt + hash in Keychain
4. Navigate to Vault List (empty state)

### Unlock
1. Show Unlock screen
2. Try biometric (if enabled) → success → load vault
3. Fallback: enter master password → re-derive key → verify against stored hash → load vault

### Add Entry
1. Open Add screen
2. Fill: app name, username, password (or generate one)
3. Encrypt password with AES-256-GCM (new random IV)
4. Store IV + ciphertext in SQLite

### View Entry
1. Tap entry in list
2. Decrypt on the fly using in-memory key
3. Show username + masked password
4. Tap to copy → clipboard cleared after 30s
5. Tap show/hide to reveal password

### Delete Entry
1. Tap delete on Entry Detail
2. Confirmation dialog
3. Remove from SQLite

---

## UX Details

### Unlock Screen
- Password field with show/hide toggle
- Biometric button (fingerprint/face icon)
- Clear error message on wrong password

### Vault List Screen
- Search bar at top (filter by app name)
- Each row: app name + username
- FAB (+) to add new entry
- Empty state: icon + "No passwords saved yet. Tap + to add one."
- Alphabetical sort

### Entry Detail Screen
- App name as title
- Username (copyable)
- Password: ●●●●● with show/hide + copy button
- "Copied!" snackbar on copy
- Edit + Delete buttons

### Add / Edit Screen
- Fields: App Name, Username, Password
- Password field: show/hide toggle
- "Generate" button → creates strong random password
- Generator options: length (default 16), uppercase, numbers, symbols
- Validation: app name required, password required
- Save button

---

## CI/CD
- GitHub Actions: build check, unit tests, release artifacts (APK + IPA)
