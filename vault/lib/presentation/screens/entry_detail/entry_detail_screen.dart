import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../application/vault/vault_controller.dart';
import '../../../application/vault/vault_state.dart';
import '../../../core/constants.dart';
import '../../../domain/models/vault_entry.dart';

class EntryDetailScreen extends ConsumerStatefulWidget {
  const EntryDetailScreen({super.key, required this.entryId});
  final String entryId;

  @override
  ConsumerState<EntryDetailScreen> createState() => _EntryDetailScreenState();
}

class _EntryDetailScreenState extends ConsumerState<EntryDetailScreen> {
  bool _showPassword = false;
  String? _plainPassword;
  Timer? _hideTimer;
  Timer? _clipboardTimer;
  bool _copied = false;

  @override
  void dispose() {
    _hideTimer?.cancel();
    _clipboardTimer?.cancel();
    super.dispose();
  }

  VaultEntry? _findEntry() {
    final state = ref.read(vaultControllerProvider);
    if (state is VaultLoaded) {
      try {
        return state.entries.firstWhere((e) => e.id == widget.entryId);
      } catch (_) {
        return null;
      }
    }
    return null;
  }

  Future<void> _togglePassword(VaultEntry entry) async {
    if (_showPassword) {
      _hideTimer?.cancel();
      setState(() { _showPassword = false; _plainPassword = null; });
      return;
    }

    final plain = await ref
        .read(vaultControllerProvider.notifier)
        .getPlainPassword(entry);

    setState(() { _showPassword = true; _plainPassword = plain; });

    _hideTimer = Timer(AppConstants.passwordHideDelay, () {
      if (mounted) setState(() { _showPassword = false; _plainPassword = null; });
    });
  }

  Future<void> _copyPassword(VaultEntry entry) async {
    final plain = _plainPassword ??
        await ref
            .read(vaultControllerProvider.notifier)
            .getPlainPassword(entry);

    await Clipboard.setData(ClipboardData(text: plain));
    setState(() => _copied = true);

    _clipboardTimer?.cancel();
    _clipboardTimer = Timer(AppConstants.clipboardClearDelay, () {
      Clipboard.setData(const ClipboardData(text: ''));
    });

    Timer(const Duration(seconds: 2), () {
      if (mounted) setState(() => _copied = false);
    });
  }

  Future<void> _deleteEntry(VaultEntry entry) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete entry?'),
        content: Text('Remove "${entry.appName}" from your vault?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await ref.read(vaultControllerProvider.notifier).deleteEntry(entry.id);
      if (mounted) context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final entry = _findEntry();
    if (entry == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('Entry not found')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(entry.appName),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Edit',
            onPressed: () => context.push('/edit/${entry.id}'),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Delete',
            onPressed: () => _deleteEntry(entry),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _InfoTile(
              label: 'App',
              value: entry.appName,
              icon: Icons.apps,
            ),
            const SizedBox(height: 16),
            _InfoTile(
              label: 'Username',
              value: entry.username,
              icon: Icons.person_outline,
              copyable: true,
            ),
            const SizedBox(height: 16),
            _PasswordTile(
              password: _showPassword ? (_plainPassword ?? '...') : '●●●●●●●●',
              isVisible: _showPassword,
              isCopied: _copied,
              onToggleVisibility: () => _togglePassword(entry),
              onCopy: () => _copyPassword(entry),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({
    required this.label,
    required this.value,
    required this.icon,
    this.copyable = false,
  });

  final String label;
  final String value;
  final IconData icon;
  final bool copyable;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Icon(icon),
        title: Text(label, style: Theme.of(context).textTheme.labelSmall),
        subtitle: Text(value, style: Theme.of(context).textTheme.bodyLarge),
        trailing: copyable
            ? IconButton(
                icon: const Icon(Icons.copy_outlined),
                onPressed: () =>
                    Clipboard.setData(ClipboardData(text: value)),
              )
            : null,
      ),
    );
  }
}

class _PasswordTile extends StatelessWidget {
  const _PasswordTile({
    required this.password,
    required this.isVisible,
    required this.isCopied,
    required this.onToggleVisibility,
    required this.onCopy,
  });

  final String password;
  final bool isVisible;
  final bool isCopied;
  final VoidCallback onToggleVisibility;
  final VoidCallback onCopy;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.key_outlined),
        title: const Text('Password',
            style: TextStyle(fontSize: 12)),
        subtitle: Text(
          password,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                fontFamily: isVisible ? 'monospace' : null,
                letterSpacing: isVisible ? 1.2 : null,
              ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(
                  isVisible ? Icons.visibility_off : Icons.visibility),
              onPressed: onToggleVisibility,
              tooltip: isVisible ? 'Hide' : 'Show',
            ),
            IconButton(
              icon: Icon(isCopied ? Icons.check : Icons.copy_outlined),
              color: isCopied
                  ? Theme.of(context).colorScheme.primary
                  : null,
              onPressed: onCopy,
              tooltip: isCopied ? 'Copied!' : 'Copy',
            ),
          ],
        ),
      ),
    );
  }
}
