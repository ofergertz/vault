import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../core/constants.dart';

class SecureStorageService {
  const SecureStorageService(this._storage);

  final FlutterSecureStorage _storage;

  Future<void> saveSalt(String salt) =>
      _storage.write(key: AppConstants.keyArgon2Salt, value: salt);

  Future<String?> getSalt() =>
      _storage.read(key: AppConstants.keyArgon2Salt);

  Future<void> saveHash(String hash) =>
      _storage.write(key: AppConstants.keyMasterHash, value: hash);

  Future<String?> getHash() =>
      _storage.read(key: AppConstants.keyMasterHash);

  Future<void> setBiometricEnabled(bool enabled) => _storage.write(
        key: AppConstants.keyBiometricEnabled,
        value: enabled.toString(),
      );

  Future<bool> isBiometricEnabled() async {
    final value = await _storage.read(key: AppConstants.keyBiometricEnabled);
    return value == 'true';
  }

  Future<bool> isSetupComplete() async {
    final salt = await getSalt();
    final hash = await getHash();
    return salt != null && hash != null;
  }
}
