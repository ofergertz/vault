import 'dart:math';

import '../../domain/services/password_generator_service.dart';

class PasswordGeneratorServiceImpl implements PasswordGeneratorService {
  static const _lowercase = 'abcdefghijklmnopqrstuvwxyz';
  static const _uppercase = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
  static const _numbers = '0123456789';
  static const _symbols = '!@#\$%^&*()-_=+[]{}|;:,.<>?';

  final _rng = Random.secure();

  @override
  String generate({
    int length = 16,
    bool uppercase = true,
    bool numbers = true,
    bool symbols = true,
  }) {
    final pool = StringBuffer(_lowercase);
    final required = <String>[];

    if (uppercase) {
      pool.write(_uppercase);
      required.add(_uppercase[_rng.nextInt(_uppercase.length)]);
    }
    if (numbers) {
      pool.write(_numbers);
      required.add(_numbers[_rng.nextInt(_numbers.length)]);
    }
    if (symbols) {
      pool.write(_symbols);
      required.add(_symbols[_rng.nextInt(_symbols.length)]);
    }

    final chars = pool.toString();
    final password = List<String>.generate(
      length - required.length,
      (_) => chars[_rng.nextInt(chars.length)],
    )..addAll(required);

    password.shuffle(_rng);
    return password.join();
  }
}
