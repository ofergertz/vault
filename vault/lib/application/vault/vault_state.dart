import '../../domain/models/vault_entry.dart';

sealed class VaultState {
  const VaultState();
}

class VaultLoading extends VaultState {
  const VaultLoading();
}

class VaultLoaded extends VaultState {
  final List<VaultEntry> entries;
  final String searchQuery;

  const VaultLoaded({required this.entries, this.searchQuery = ''});

  List<VaultEntry> get filtered {
    if (searchQuery.isEmpty) return entries;
    return entries
        .where((e) =>
            e.appName.toLowerCase().contains(searchQuery.toLowerCase()))
        .toList();
  }
}

class VaultError extends VaultState {
  final String message;
  const VaultError(this.message);
}
