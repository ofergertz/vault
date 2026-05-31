import 'package:uuid/uuid.dart';

class VaultEntry {
  final String id;
  final String appName;
  final String username;
  final String encryptedPassword; // AES-256-GCM ciphertext (base64)
  final String iv;                // 12-byte nonce (base64)
  final DateTime createdAt;
  final DateTime updatedAt;

  const VaultEntry({
    required this.id,
    required this.appName,
    required this.username,
    required this.encryptedPassword,
    required this.iv,
    required this.createdAt,
    required this.updatedAt,
  });

  factory VaultEntry.create({
    required String appName,
    required String username,
    required String encryptedPassword,
    required String iv,
  }) {
    final now = DateTime.now();
    return VaultEntry(
      id: const Uuid().v4(),
      appName: appName,
      username: username,
      encryptedPassword: encryptedPassword,
      iv: iv,
      createdAt: now,
      updatedAt: now,
    );
  }

  VaultEntry copyWith({
    String? appName,
    String? username,
    String? encryptedPassword,
    String? iv,
    DateTime? updatedAt,
  }) {
    return VaultEntry(
      id: id,
      appName: appName ?? this.appName,
      username: username ?? this.username,
      encryptedPassword: encryptedPassword ?? this.encryptedPassword,
      iv: iv ?? this.iv,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'app_name': appName,
        'username': username,
        'encrypted_password': encryptedPassword,
        'iv': iv,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      };

  factory VaultEntry.fromJson(Map<String, dynamic> json) => VaultEntry(
        id: json['id'] as String,
        appName: json['app_name'] as String,
        username: json['username'] as String,
        encryptedPassword: json['encrypted_password'] as String,
        iv: json['iv'] as String,
        createdAt: DateTime.parse(json['created_at'] as String),
        updatedAt: DateTime.parse(json['updated_at'] as String),
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is VaultEntry && other.id == id);

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'VaultEntry(id: $id, appName: $appName)';
}
