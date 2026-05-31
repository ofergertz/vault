abstract interface class PasswordGeneratorService {
  /// Generates a random password with the given options.
  String generate({
    int length = 16,
    bool uppercase = true,
    bool numbers = true,
    bool symbols = true,
  });
}
