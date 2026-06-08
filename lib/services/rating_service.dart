import 'package:shared_preferences/shared_preferences.dart';

import '../config/app_config.dart';

class RatingService {
  static const _ratingKey = AppConfig.ratingStatusKey;
  static const _lastPromptKey = AppConfig.lastRatingPromptKey;
  static const _promptIntervalMs = 10 * 24 * 60 * 60 * 1000;

  Future<bool> shouldShowRatingPrompt() async {
    final prefs = await SharedPreferences.getInstance();
    final status = prefs.getString(_ratingKey);

    if (status == 'rated') return false;

    if (status == 'dismissed') {
      final lastPrompt = prefs.getString(_lastPromptKey);
      if (lastPrompt != null) {
        final nextPrompt =
            int.parse(lastPrompt) + _promptIntervalMs;
        if (DateTime.now().millisecondsSinceEpoch < nextPrompt) {
          return false;
        }
      }
    }

    return true;
  }

  Future<void> rateApp() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_ratingKey, 'rated');
  }

  Future<void> dismissRating() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_ratingKey, 'dismissed');
    await prefs.setString(
      _lastPromptKey,
      DateTime.now().millisecondsSinceEpoch.toString(),
    );
  }
}
