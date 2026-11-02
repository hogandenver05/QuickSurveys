import 'dart:math';

class SurveyCodeGenerator {
  static const String _characters =
      'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';

  static final Random _random = Random.secure();

  static String generate() {
    return List.generate(
      6,
          (_) => _characters[_random.nextInt(_characters.length)],
    ).join();
  }
}