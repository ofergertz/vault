import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../application/vault/vault_controller.dart';
import '../../../application/vault/vault_state.dart';
import '../../../domain/models/vault_entry.dart';
import '../../../infrastructure/storage/password_generator_service_impl.dart';
import '../../widgets/password_field.dart';

class AddEditScreen extends ConsumerStatefulWidget {
  const AddEditScreen({super.key, this.editEntryId});
  final String? editEntryId;

  @override
  ConsumerState<AddEditScreen> createState() => _AddEditScreenState();
}

class _AddEditScreenState extends ConsumerState<AddEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final _appNameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _generator = PasswordGeneratorServiceImpl();

  bool _loading = false;
  VaultEntry? _existingEntry;

  @override
  void initState() {
    super.initState();
    if (widget.editEntryId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _loadEntry());
    }
  }

  void _loadEntry() {
    final state = ref.read(vaultControllerProvider);
    if (state is VaultLoaded) {
      try {
        final entry =
            state.entries.firstWhere((e) => e.id == widget.editEntryId);
        _existingEntry = entry;
        _appNameController.text = entry.appName;
        _usernameController.text = entry.username;
        // Password is encrypted — user must re-enter to change
        setState(() {});
      } catch (_) {}
    }
  }

  Future<void> _generatePassword() async {
    final password = _generator.generate(
      length: 16,
      uppercase: true,
      numbers: true,
      symbols: true,
    );
    _passwordController.text = password;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    try {
      final controller = ref.read(vaultControllerProvider.notifier);

      if (_existingEntry != null) {
        await controller.updateEntry(
          existing: _existingEntry!,
          appName: _appNameController.text.trim(),
          username: _usernameController.text.trim(),
          plainPassword: _passwordController.text,
        );
      } else {
        await controller.addEntry(
          appName: _appNameController.text.trim(),
          username: _usernameController.text.trim(),
          plainPassword: _passwordController.text,
        );
      }

      if (mounted) context.pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _appNameController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = _existingEntry != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? 'Edit Entry' : 'Add Entry'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _appNameController,
                decoration: const InputDecoration(
                  labelText: 'App Name',
                  hintText: 'e.g. Netflix',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.apps),
                ),
                textCapitalization: TextCapitalization.words,
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _usernameController,
                decoration: const InputDecoration(
                  labelText: 'Username / Email',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person_outline),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              PasswordField(
                controller: _passwordController,
                label: isEdit ? 'New password (leave blank to keep)' : 'Password',
                validator: (v) {
                  if (!isEdit && (v == null || v.isEmpty)) return 'Required';
                  return null;
                },
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: _generatePassword,
                  icon: const Icon(Icons.auto_fix_high, size: 18),
                  label: const Text('Generate strong password'),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _loading ? null : _save,
                  child: _loading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(isEdit ? 'Save Changes' : 'Save'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
