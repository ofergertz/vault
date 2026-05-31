import '../models/vault_entry.dart';

abstract interface class VaultRepository {
  /// Returns all entries sorted alphabetically by appName.
  Future<List<VaultEntry>> getAll();

  /// Returns a single entry by id, or null if not found.
  Future<VaultEntry?> getById(String id);

  /// Inserts a new entry.
  Future<void> insert(VaultEntry entry);

  /// Updates an existing entry.
  Future<void> update(VaultEntry entry);

  /// Deletes an entry by id.
  Future<void> delete(String id);
}
