# Vault — Development Tasks

Ordered by dependency. Pick up from top to bottom.

---

## Phase 1 — Foundation

### T01 — Project Setup
**Layer:** Infrastructure
Set up Flutter project with Riverpod, go_router, sqflite, flutter_secure_storage, local_auth. Configure folder structure per layer architecture.
**Deps:** none

### T02 — VaultEntry Model
**Layer:** Domain
Define `VaultEntry` data class with id, appName, username, encryptedPassword, iv, createdAt, updatedAt.
**Deps:** T01

### T03 — SQLite Repository
**Layer:** Infrastructure
Create `SqliteVaultRepository` — initialize DB, CRUD operations for VaultEntry. Implement `VaultRepository` interface.
**Deps:** T02

### T04 — SecureStorageService
**Layer:** Infrastructure
Wrapper around flutter_secure_storage. Methods: saveHash, getHash, saveSalt, getSalt, saveBiometricPref, getBiometricPref.
**Deps:** T01

---

## Phase 2 — Crypto & Auth

### T05 — CryptoService
**Layer:** Domain
Implement Argon2id key derivation (64MB, 3 iter, 4 parallelism). Implement AES-256-GCM encrypt/decrypt. Return IV + ciphertext as base64. Throw on auth tag mismatch.
**Deps:** T01

### T06 — PasswordGeneratorService
**Layer:** Domain
Pure function: generate random password. Options: length (default 16), uppercase, numbers, symbols. No side effects.
**Deps:** T01

### T07 — BiometricService
**Layer:** Domain
Wrap `local_auth`. Methods: isAvailable(), authenticate(reason). Return bool.
**Deps:** T01

### T08 — AuthController (Riverpod)
**Layer:** Application
State machine: locked / unlocked / setup. Handles: first launch setup, master password unlock, biometric unlock, lock/logout. Holds derived key in memory only.
**Deps:** T05, T06, T07, T04

---

## Phase 3 — Business Logic

### T09 — VaultController (Riverpod)
**Layer:** Application
Depends on AuthController (needs key). CRUD: loadAll, addEntry, updateEntry, deleteEntry. Encrypts/decrypts via CryptoService.
**Deps:** T08, T03, T05

---

## Phase 4 — Navigation

### T10 — go_router Setup
**Layer:** Presentation
Define routes: /unlock, /vault, /entry/:id, /add, /edit/:id. Auth guard: redirect to /unlock if locked.
**Deps:** T08

---

## Phase 5 — Screens

### T11 — Unlock Screen
**Layer:** Presentation
Password field + show/hide. Biometric button. Error message on failure. Calls AuthController.unlockWithPassword / unlockWithBiometric.
**Deps:** T08, T10

### T12 — Vault List Screen
**Layer:** Presentation
Search bar (filter by appName). List of entries (appName + username). FAB (+). Empty state. Alphabetical sort. Navigate to EntryDetail or AddEdit.
**Deps:** T09, T10

### T13 — Entry Detail Screen
**Layer:** Presentation
Show appName, username (copyable), masked password with show/hide + copy. "Copied!" snackbar. Auto-clear clipboard after 30s. Edit + Delete buttons with confirmation dialog.
**Deps:** T09, T10

### T14 — Add / Edit Screen
**Layer:** Presentation
Form: appName, username, password (show/hide). Generate button → PasswordGeneratorService. Validation. Save calls VaultController.
**Deps:** T09, T10, T06

---

## Phase 6 — Polish & Testing

### T15 — Unit Tests: CryptoService
**Layer:** Domain
Test: key derivation consistency, encrypt→decrypt roundtrip, tamper detection (modified ciphertext throws).
**Deps:** T05

### T16 — Unit Tests: VaultController
**Layer:** Application
Test: add/update/delete, encrypt on save, decrypt on load, wrong key fails gracefully.
**Deps:** T09

### T17 — Widget Tests: Screens
**Layer:** Presentation
Smoke tests for all 4 screens. Test copy feedback, empty state, biometric fallback flow.
**Deps:** T11, T12, T13, T14

### T18 — CI/CD: GitHub Actions
**Layer:** Infrastructure
Pipeline: flutter analyze, flutter test, flutter build apk, flutter build ipa (on tag).
**Deps:** T17

---

## Summary

| Phase | Tasks | Est. |
|---|---|---|
| Foundation | T01–T04 | ~1 day |
| Crypto & Auth | T05–T08 | ~2 days |
| Business Logic | T09 | ~1 day |
| Navigation | T10 | ~0.5 day |
| Screens | T11–T14 | ~2 days |
| Polish & Tests | T15–T18 | ~1.5 days |
| **Total** | **18 tasks** | **~8 days** |
