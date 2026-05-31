import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../domain/models/vault_entry.dart';
import '../../domain/repositories/vault_repository.dart';
import '../../domain/services/crypto_service.dart';
import '../../infrastructure/crypto/crypto_service_impl.dart';
import '../../infrastructure/storage/secure_storage_service.dart';
import '../../infrastructure/storage/sqlite_vault_repository.dart';
import '../auth/auth_controller.dart';
import 'vault_state.dart';

final vaultControllerProvider =
    StateNotifierProvider<VaultController, VaultState>(
  (ref) => VaultController(
    repository: SqliteVaultRepository(),
    cryptoService: CryptoServiceImpl(),
    secureStorage: SecureStorageService(const FlutterSecureStorage()),
    ref: ref,
  ),
);

class VaultController extends StateNotifier<VaultState> {
  VaultController({
    required this.repository,
    required this.cryptoService,
    required this.secureStorage,
    required this.ref,
  }) : super(const VaultLoading());

  final VaultRepository repository;
  final CryptoService cryptoService;
  final SecureStorageService secureStorage;
  final Ref ref;

  List<int> get _key =>
      ref.read(authControllerProvider.notifier).currentKey!;

  Future<void> loadAll() async {
    state = const VaultLoading();
    try {
      final entries = await repository.getAll();
      state = VaultLoaded(entries: entries);
    } catch (e) {
      state = VaultError('Failed to load vault: $e');
    }
  }

  Future<void> addEntry({
    required String appName,
    required String username,
    required String plainPassword,
  }) async {
    try {
      final (:ciphertext, :iv) =
          await cryptoService.encrypt(_key, plainPassword);
      final entry = VaultEntry.create(
        appName: appName,
        username: username,
        encryptedPassword: ciphertext,
        iv: iv,
      );
      await repository.insert(entry);
      await loadAll();
    } catch (e) {
      state = VaultError('Failed to add entry: $e');
    }
  }

  Future<void> updateEntry({
    required VaultEntry existing,
    required String appName,
    required String username,
    required String plainPassword,
  }) async {
    try {
      final (:ciphertext, :iv) =
          await cryptoService.encrypt(_key, plainPassword);
      final updated = existing.copyWith(
        appName: appName,
        username: username,
        encryptedPassword: ciphertext,
        iv: iv,
      );
      await repository.update(updated);
      await loadAll();
    } catch (e) {
      state = VaultError('Failed to update entry: $e');
    }
  }

  Future<void> deleteEntry(String id) async {
    try {
      await repository.delete(id);
      await loadAll();
    } catch (e) {
      state = VaultError('Failed to delete entry: $e');
    }
  }

  /// Decrypts and returns the plain password for a given entry.
  Future<String> getPlainPassword(VaultEntry entry) async {
    return cryptoService.decrypt(_key, entry.encryptedPassword, entry.iv);
  }

  void search(String query) {
    final current = state;
    if (current is VaultLoaded) {
      state = VaultLoaded(entries: current.entries, searchQuery: query);
    }
  }
}
