# Vault — Password Manager App: Architecture Document

> **Version:** 2.0 — Includes UX Layer & Biometric Authentication
> **Updated:** 2026-05-31
> **Status:** Developer-Ready

---

## 1. Summary

Vault is a local-first, offline Flutter password manager. It stores encrypted credentials on-device using AES-256 encryption, protected by a user-defined master password. This document describes the full architecture including the presentation (UX) layer, biometric authentication flow, and password generation utility. The app follows Clean Architecture (Presentation → Domain → Data), keeping business logic strictly decoupled from UI and storage concerns.

---

## 2. Layer Overview

```
┌─────────────────────────────────────────────────────┐
│                  PRESENTATION LAYER                  │
│  Screens · Widgets · State (Riverpod/Bloc)           │
├─────────────────────────────────────────────────────┤
│                    DOMAIN LAYER                      │
│  Use Cases · Entities · Repository Interfaces        │
│  Pure Dart — no Flutter, no packages                 │
├─────────────────────────────────────────────────────┤
│                     DATA LAYER                       │
│  Repository Impls · Local DB · Secure Storage        │
└─────────────────────────────────────────────────────┘
```

---

## 3. Components

### 3.1 Presentation Layer

#### 3.1.1 Screens

| Screen | Route | Purpose |
|---|---|---|
| `UnlockScreen` | `/` | App entry — biometric + master password auth |
| `VaultListScreen` | `/vault` | Browse all saved entries |
| `EntryDetailScreen` | `/vault/:id` | View/copy credential fields |
| `AddEditScreen` | `/vault/edit` (or `/vault/:id/edit`) | Create or update an entry |

#### 3.1.2 Screen Specifications

**UnlockScreen**
- Password text field with show/hide toggle (eye icon)
- Biometric unlock button (fingerprint / Face ID icon) — shown only when biometric is enabled
- "Wrong password" error message displayed inline (no dialog)
- On first launch: only master password visible (biometric not yet enrolled)
- Auto-trigger biometric on screen load if enabled

**VaultListScreen**
- Search bar (debounced, ~300 ms) at top — filters by app name / username
- List tiles: favicon/icon placeholder + app name (bold) + username (muted)
- FAB (`+`) in bottom-right → navigates to `AddEditScreen`
- Empty state: illustration + "No entries yet. Tap + to add one." text
- Pull-to-refresh (no-op for local; reserved for future sync)

**EntryDetailScreen**
- App name as header
- Username field (tap-to-copy with `Copied!` snackbar)
- Password field hidden by default (●●●●●) — show/hide toggle
- Tap-to-copy on password — same snackbar feedback
- Edit button → `AddEditScreen` in edit mode
- Delete button → confirmation bottom sheet → delete use case

**AddEditScreen**
- Fields: App Name, Username, Password (show/hide toggle)
- Password Generator button (icon button adjacent to password field) → opens `PasswordGeneratorSheet`
- Simple validation: no empty required fields, minimum password length warning
- Save button (disabled until valid)
- Title changes: "Add Entry" vs "Edit Entry"

#### 3.1.3 Shared Widgets

- `PasswordField` — reusable field with show/hide toggle
- `CopyableField` — tap-to-copy with snackbar feedback
- `PasswordGeneratorSheet` — bottom sheet with generator controls
- `EmptyStateWidget` — illustration + message
- `ConfirmDeleteSheet` — bottom sheet confirmation

#### 3.1.4 State Management

Use **Riverpod** (preferred) or Bloc/Cubit. Recommended providers:

| Provider | Type | Purpose |
|---|---|---|
| `authStateProvider` | `StateNotifier<AuthState>` | Lock/unlock state, biometric availability |
| `vaultEntriesProvider` | `AsyncNotifier<List<VaultEntry>>` | All entries |
| `searchQueryProvider` | `StateProvider<String>` | Live search filter |
| `filteredEntriesProvider` | `Provider<List<VaultEntry>>` | Derived — filtered list |
| `entryDetailProvider(id)` | `FutureProvider` | Single entry by ID |

---

### 3.2 Domain Layer (Pure Dart)

#### 3.2.1 Entities

```dart
class VaultEntry {
  final String id;          // UUID v4
  final String appName;
  final String username;
  final String encryptedPassword;
  final DateTime createdAt;
  final DateTime updatedAt;
}
```

#### 3.2.2 Repository Interface

```dart
abstract class VaultRepository {
  Future<List<VaultEntry>> getAll();
  Future<VaultEntry?> getById(String id);
  Future<void> save(VaultEntry entry);
  Future<void> delete(String id);
}

abstract class AuthRepository {
  Future<bool> verifyMasterPassword(String password);
  Future<void> setMasterPassword(String password);
  Future<bool> isBiometricEnabled();
  Future<void> setBiometricEnabled(bool enabled);
  Future<bool> isBiometricAvailable();
}
```

#### 3.2.3 Use Cases

| Use Case | Input | Output |
|---|---|---|
| `UnlockWithPasswordUseCase` | `String password` | `bool success` |
| `UnlockWithBiometricUseCase` | — | `bool success` |
| `EnableBiometricUseCase` | — | `void` (only after verified session) |
| `GetAllEntriesUseCase` | — | `List<VaultEntry>` |
| `GetEntryByIdUseCase` | `String id` | `VaultEntry?` |
| `SaveEntryUseCase` | `VaultEntry entry` | `void` |
| `DeleteEntryUseCase` | `String id` | `void` |
| `GeneratePasswordUseCase` | `PasswordOptions options` | `String password` |

#### 3.2.4 Password Generator (Pure Utility)

Lives in Domain — no dependencies on Flutter or packages.

```dart
class PasswordOptions {
  final int length;           // default: 16, range: 8–64
  final bool useUppercase;    // default: true
  final bool useNumbers;      // default: true
  final bool useSymbols;      // default: true
}

// GeneratePasswordUseCase uses dart:math SecureRandom
String generatePassword(PasswordOptions options);
```

**Character pools:**
- Lowercase: `a-z` (always included)
- Uppercase: `A-Z`
- Numbers: `0-9`
- Symbols: `!@#$%^&*()-_=+[]{}|;:,.<>?`

Algorithm: fill from each enabled pool to guarantee at least one character from each, then fill remainder randomly from combined pool, then shuffle.

---

### 3.3 Data Layer

#### 3.3.1 Local Database — `VaultLocalDataSource`

- **Package:** `sqflite` (SQLite)
- Stores `VaultEntry` rows; passwords stored encrypted (AES-256-GCM)
- Encryption key derived from master password via PBKDF2 (100k iterations, SHA-256)
- Key is held in memory only during an active session; cleared on lock

**Schema:**

```sql
CREATE TABLE vault_entries (
  id           TEXT PRIMARY KEY,
  app_name     TEXT NOT NULL,
  username     TEXT NOT NULL,
  enc_password TEXT NOT NULL,  -- AES-256-GCM base64
  created_at   INTEGER NOT NULL,
  updated_at   INTEGER NOT NULL
);
```

#### 3.3.2 Secure Storage — `SecureStorageDataSource`

- **Package:** `flutter_secure_storage`
- Stores:
  - `master_password_hash` — bcrypt hash of master password
  - `biometric_enabled` — `"true"` / `"false"`
  - `biometric_verified_once` — `"true"` once first master password unlock succeeds (gate for biometric enrolment)

#### 3.3.3 Biometric Auth — `BiometricAuthDataSource`

- **Package:** `local_auth`
- Wraps `LocalAuthentication.authenticate()`
- Returns `bool` — success or failure/cancelled
- Reports availability (`canCheckBiometrics`, `getAvailableBiometrics`)

---

## 4. Biometric Authentication Flow

```
App Launch
    │
    ▼
UnlockScreen loads
    │
    ├─ biometric_enabled == true?
    │       │
    │       ▼ YES
    │   Trigger biometric prompt automatically
    │       │
    │       ├── SUCCESS → decrypt vault key → unlock → VaultListScreen
    │       │
    │       └── FAIL/CANCEL → show password field
    │
    └─ biometric_enabled == false → show password field only
          │
          ▼
    User enters master password
          │
          ├── INVALID → show inline error "Wrong password"
          │
          └── VALID
                │
                ├── set biometric_verified_once = true (if not already)
                │
                ├── biometric_enabled == false && biometric available?
                │       └── Prompt: "Enable biometric unlock?" (one-time nudge)
                │
                └── decrypt vault key → unlock → VaultListScreen
```

**Biometric Enrolment Rule:**
Biometric can only be enabled after the first successful master password unlock in the current install. This prevents someone from enabling biometric without knowing the password.

**Key Security Note:**
The vault decryption key is derived at unlock time and held in memory. On lock (app background / manual lock), the key is zeroed from memory. Biometric auth itself does not store the key — it only gates the password-unlock code path.

---

## 5. Data Flow

### 5.1 Unlock (Biometric)

```
UnlockScreen
  → UnlockWithBiometricUseCase
      → BiometricAuthDataSource.authenticate()
          → [OS biometric prompt]
      → if success: AuthRepository.deriveKey(storedHash) // re-derive from stored hash
      → AuthState = Unlocked
  → Navigator → VaultListScreen
```

### 5.2 Load Vault Entries

```
VaultListScreen mounts
  → GetAllEntriesUseCase
      → VaultRepository.getAll()
          → VaultLocalDataSource.queryAll()
              → SQLite SELECT *
              → decrypt each enc_password with in-memory key
      → return List<VaultEntry>
  → filteredEntriesProvider derives filtered list from search query
```

### 5.3 Save Entry

```
AddEditScreen "Save" tap
  → SaveEntryUseCase(entry)
      → encrypt password with in-memory AES key
      → VaultRepository.save(entry)
          → VaultLocalDataSource.upsert(entry)
              → SQLite INSERT OR REPLACE
  → invalidate vaultEntriesProvider
  → Navigator.pop()
```

### 5.4 Copy Password (Detail Screen)

```
User taps password field (EntryDetailScreen)
  → CopyableField widget
      → Clipboard.setData(decryptedPassword)
      → show "Copied!" SnackBar
      → (no use case — clipboard is a UI concern)
```

---

## 6. API Contracts (Internal)

### 6.1 VaultRepository

```dart
abstract class VaultRepository {
  Future<List<VaultEntry>> getAll();
  Future<VaultEntry?> getById(String id);
  Future<void> save(VaultEntry entry);    // insert or update
  Future<void> delete(String id);
}
```

### 6.2 AuthRepository

```dart
abstract class AuthRepository {
  Future<bool> verifyMasterPassword(String password);
  Future<void> setMasterPassword(String password);   // first-time setup
  Future<bool> isBiometricAvailable();               // hardware check
  Future<bool> isBiometricEnabled();                 // user preference
  Future<void> setBiometricEnabled(bool enabled);
  Future<bool> hasVerifiedOnce();                    // gate for biometric enrolment
}
```

### 6.3 PasswordGeneratorUseCase

```dart
// Input
class PasswordOptions {
  final int length;
  final bool useUppercase;
  final bool useNumbers;
  final bool useSymbols;
}

// Output: String — the generated password
```

### 6.4 PasswordGeneratorSheet (Widget Contract)

```dart
// Opens as bottom sheet, returns generated password or null (dismissed)
Future<String?> showPasswordGeneratorSheet(BuildContext context);
```

---

## 7. Technology Choices

| Technology | Package | Reason |
|---|---|---|
| Flutter | — | Cross-platform (iOS + Android) from one codebase |
| State management | `flutter_riverpod` | Testable, composable, minimal boilerplate |
| Local DB | `sqflite` | Mature, reliable SQLite wrapper |
| Secure storage | `flutter_secure_storage` | Keychain (iOS) / Keystore (Android) backed |
| Biometric auth | `local_auth` | Official Flutter plugin, handles Face ID + fingerprint |
| Encryption | `pointycastle` or `cryptography` | AES-256-GCM for passwords at rest |
| Password hashing | `bcrypt` | Slow hash for master password verification |
| KDF | PBKDF2 (via `pointycastle`) | Key derivation from master password |
| UUID | `uuid` | Entry IDs |
| Navigation | `go_router` | Declarative routing, deep links ready |

---

## 8. Project Structure

```
lib/
├── main.dart
├── app.dart                        # MaterialApp, router setup
│
├── presentation/
│   ├── screens/
│   │   ├── unlock_screen.dart
│   │   ├── vault_list_screen.dart
│   │   ├── entry_detail_screen.dart
│   │   └── add_edit_screen.dart
│   ├── widgets/
│   │   ├── password_field.dart
│   │   ├── copyable_field.dart
│   │   ├── password_generator_sheet.dart
│   │   ├── empty_state_widget.dart
│   │   └── confirm_delete_sheet.dart
│   └── providers/
│       ├── auth_provider.dart
│       ├── vault_provider.dart
│       └── search_provider.dart
│
├── domain/
│   ├── entities/
│   │   └── vault_entry.dart
│   ├── repositories/
│   │   ├── vault_repository.dart
│   │   └── auth_repository.dart
│   └── usecases/
│       ├── unlock_with_password_usecase.dart
│       ├── unlock_with_biometric_usecase.dart
│       ├── enable_biometric_usecase.dart
│       ├── get_all_entries_usecase.dart
│       ├── get_entry_by_id_usecase.dart
│       ├── save_entry_usecase.dart
│       ├── delete_entry_usecase.dart
│       └── generate_password_usecase.dart
│
└── data/
    ├── datasources/
    │   ├── vault_local_datasource.dart
    │   ├── secure_storage_datasource.dart
    │   └── biometric_auth_datasource.dart
    ├── repositories/
    │   ├── vault_repository_impl.dart
    │   └── auth_repository_impl.dart
    └── models/
        └── vault_entry_model.dart      # DB ↔ Entity mapper
```

---

## 9. Risks & Trade-offs

| Risk | Severity | Mitigation |
|---|---|---|
| In-memory key exposure | High | Zero key on lock; use `SecureBytes` / overwrite buffer; keep key lifetime minimal |
| Master password forgotten = data lost | High | Accept this (local-first design); document clearly; consider optional encrypted backup in v2 |
| Biometric spoofing | Medium | Use `biometricOnly: false` + require device credential fallback via `local_auth` options |
| SQLite file accessible on rooted devices | Medium | Encryption at rest (AES-256) covers this; avoid storing plaintext anywhere |
| `flutter_secure_storage` wiped on Android reinstall | Medium | Warn user; consider offering export before uninstall |
| Password generator weak entropy | Low | Use `dart:math` `Random.secure()` — cryptographically secure PRNG |
| State leakage on screen capture | Low | Use `FLAG_SECURE` (Android) / iOS equivalent to block screenshots on sensitive screens |

---

## 10. Tasks for Tech Lead

> Breakdown for implementation sprint(s).

### Sprint 1 — Foundation
- [ ] **T1.1** Project scaffold — Flutter + Riverpod + go_router, Clean Architecture folder structure
- [ ] **T1.2** Domain entities: `VaultEntry`, `PasswordOptions`
- [ ] **T1.3** Repository interfaces: `VaultRepository`, `AuthRepository`
- [ ] **T1.4** `VaultLocalDataSource` — SQLite schema, CRUD, AES-256-GCM encryption
- [ ] **T1.5** `SecureStorageDataSource` — master password hash, biometric flag storage
- [ ] **T1.6** Repository implementations wiring data sources

### Sprint 2 — Auth & Core Logic
- [ ] **T2.1** `UnlockWithPasswordUseCase` + `AuthRepository` master password flow
- [ ] **T2.2** `BiometricAuthDataSource` — `local_auth` integration, availability check
- [ ] **T2.3** `UnlockWithBiometricUseCase` + `EnableBiometricUseCase`
- [ ] **T2.4** `AuthStateNotifier` — lock/unlock state, biometric trigger on screen load
- [ ] **T2.5** `GeneratePasswordUseCase` — pure Dart, `SecureRandom`, pool logic

### Sprint 3 — Screens & UX
- [ ] **T3.1** `UnlockScreen` — password field, biometric button, error state
- [ ] **T3.2** `VaultListScreen` — list tiles, search, FAB, empty state
- [ ] **T3.3** `EntryDetailScreen` — masked password, tap-to-copy, edit/delete
- [ ] **T3.4** `AddEditScreen` — form fields, validation, save flow
- [ ] **T3.5** `PasswordGeneratorSheet` — bottom sheet, live preview, insert to field
- [ ] **T3.6** Shared widgets: `PasswordField`, `CopyableField`, `ConfirmDeleteSheet`

### Sprint 4 — Polish & Security Hardening
- [ ] **T4.1** `FLAG_SECURE` on Android for sensitive screens (prevent screenshots)
- [ ] **T4.2** Auto-lock on app background (configurable timeout)
- [ ] **T4.3** Unit tests: all use cases + password generator
- [ ] **T4.4** Widget tests: `UnlockScreen`, `AddEditScreen` validation
- [ ] **T4.5** Integration test: full unlock → add entry → view entry → delete flow
- [ ] **T4.6** iOS `NSFaceIDUsageDescription` + Android biometric permissions in manifests

---

## 11. Dependency Additions (pubspec.yaml)

```yaml
dependencies:
  flutter_riverpod: ^2.5.0
  go_router: ^13.0.0
  sqflite: ^2.3.0
  flutter_secure_storage: ^9.0.0
  local_auth: ^2.2.0
  pointycastle: ^3.7.0      # AES-256-GCM + PBKDF2
  bcrypt: ^1.1.3
  uuid: ^4.3.0

dev_dependencies:
  mockito: ^5.4.0
  flutter_test:
    sdk: flutter
```

---

*End of Architecture Document — Vault v2.0*
