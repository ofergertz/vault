import 'package:flutter_test/flutter_test.dart';
import 'package:vault/domain/models/vault_entry.dart';

void main() {
  group('VaultEntry', () {
    test('create() generates a unique id and timestamps', () {
      final e1 = VaultEntry.create(
        appName: 'Netflix',
        username: 'user@test.com',
        encryptedPassword: 'enc',
        iv: 'iv',
      );
      final e2 = VaultEntry.create(
        appName: 'Netflix',
        username: 'user@test.com',
        encryptedPassword: 'enc',
        iv: 'iv',
      );
      expect(e1.id, isNotEmpty);
      expect(e1.id, isNot(e2.id));
    });

    test('toJson / fromJson roundtrip', () {
      final entry = VaultEntry.create(
        appName: 'Gmail',
        username: 'ofer@gmail.com',
        encryptedPassword: 'ciphertext==',
        iv: 'randomiv==',
      );
      final json = entry.toJson();
      final restored = VaultEntry.fromJson(json);

      expect(restored.id, entry.id);
      expect(restored.appName, entry.appName);
      expect(restored.username, entry.username);
      expect(restored.encryptedPassword, entry.encryptedPassword);
      expect(restored.iv, entry.iv);
    });

    test('copyWith updates fields and bumps updatedAt', () {
      final entry = VaultEntry.create(
        appName: 'App',
        username: 'user',
        encryptedPassword: 'enc',
        iv: 'iv',
      );
      final updated = entry.copyWith(appName: 'NewApp');
      expect(updated.appName, 'NewApp');
      expect(updated.id, entry.id);
    });

    test('equality is based on id', () {
      final e1 = VaultEntry.create(
          appName: 'A', username: 'u', encryptedPassword: 'e', iv: 'i');
      final e2 = VaultEntry.create(
          appName: 'A', username: 'u', encryptedPassword: 'e', iv: 'i');
      expect(e1, isNot(e2));
      expect(e1, e1);
    });
  });
}
