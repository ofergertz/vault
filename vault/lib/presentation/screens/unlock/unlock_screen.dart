import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../application/auth/auth_controller.dart';
import '../../../application/auth/auth_state.dart';
import '../../widgets/password_field.dart';

class UnlockScreen extends ConsumerStatefulWidget {
  const UnlockScreen({super.key});

  @override
  ConsumerState<UnlockScreen> createState() => _UnlockScreenState();
}

class _UnlockScreenState extends ConsumerState<UnlockScreen> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _loading = true; _error = null; });

    try {
      final authState = ref.read(authControllerProvider);
      final controller = ref.read(authControllerProvider.notifier);

      if (authState is AuthSetupRequired) {
        await controller.setup(_passwordController.text);
      } else {
        await controller.unlockWithPassword(_passwordController.text);
      }
    } catch (e) {
      setState(() => _error = 'Wrong password. Try again.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _biometricUnlock() async {
    final success = await ref
        .read(authControllerProvider.notifier)
        .unlockWithBiometric();
    if (!success && mounted) {
      setState(() => _error = 'Biometric authentication failed');
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final isSetup = authState is AuthSetupRequired;
    final biometricAvailable =
        authState is AuthLocked && authState.biometricAvailable;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(32),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.lock_outline, size: 72),
                  const SizedBox(height: 16),
                  Text(
                    isSetup ? 'Create Master Password' : 'Unlock Vault',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  if (isSetup) ...[
                    const SizedBox(height: 8),
                    Text(
                      'This password protects all your data. Don\'t forget it.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                  const SizedBox(height: 32),
                  PasswordField(
                    controller: _passwordController,
                    label: isSetup ? 'Create password' : 'Master password',
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _submit(),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Required';
                      if (isSetup && v.length < 8) {
                        return 'Minimum 8 characters';
                      }
                      return null;
                    },
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      _error!,
                      style: TextStyle(
                          color: Theme.of(context).colorScheme.error),
                    ),
                  ],
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: _loading ? null : _submit,
                      child: _loading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(isSetup ? 'Create' : 'Unlock'),
                    ),
                  ),
                  if (biometricAvailable) ...[
                    const SizedBox(height: 16),
                    TextButton.icon(
                      onPressed: _biometricUnlock,
                      icon: const Icon(Icons.fingerprint),
                      label: const Text('Use biometrics'),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
