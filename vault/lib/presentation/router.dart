import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../application/auth/auth_controller.dart';
import '../application/auth/auth_state.dart';
import 'screens/add_edit/add_edit_screen.dart';
import 'screens/entry_detail/entry_detail_screen.dart';
import 'screens/unlock/unlock_screen.dart';
import 'screens/vault_list/vault_list_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authNotifier = ref.watch(authControllerProvider.notifier);

  return GoRouter(
    initialLocation: '/unlock',
    refreshListenable: _AuthStateListenable(ref),
    redirect: (context, state) {
      final authState = ref.read(authControllerProvider);
      final isUnlocked = authState is AuthUnlocked;
      final isSetupRoute = state.matchedLocation == '/setup';
      final isUnlockRoute = state.matchedLocation == '/unlock';

      if (authState is AuthLoading) return null;
      if (authState is AuthSetupRequired && !isSetupRoute) return '/unlock';
      if (!isUnlocked && !isUnlockRoute && !isSetupRoute) return '/unlock';
      if (isUnlocked && (isUnlockRoute || isSetupRoute)) return '/vault';

      return null;
    },
    routes: [
      GoRoute(
        path: '/unlock',
        builder: (context, state) => const UnlockScreen(),
      ),
      GoRoute(
        path: '/vault',
        builder: (context, state) => const VaultListScreen(),
      ),
      GoRoute(
        path: '/entry/:id',
        builder: (context, state) =>
            EntryDetailScreen(entryId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/add',
        builder: (context, state) => const AddEditScreen(),
      ),
      GoRoute(
        path: '/edit/:id',
        builder: (context, state) =>
            AddEditScreen(editEntryId: state.pathParameters['id']),
      ),
    ],
  );
});

/// Bridges Riverpod auth state changes to GoRouter's refresh mechanism.
class _AuthStateListenable extends ChangeNotifier {
  _AuthStateListenable(Ref ref) {
    ref.listen(authControllerProvider, (_, __) => notifyListeners());
  }
}
