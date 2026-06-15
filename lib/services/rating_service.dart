import 'package:shared_preferences/shared_preferences.dart';

import '../config/app_config.dart';

enum RatingPromptTrigger {
  /// Shown ~5 minutes after first app open.
  timeInApp,

  /// Shown after the user saves their 2nd recording.
  recordingSaved,

  /// Shown after listening to a recording in the panel.
  recordingPlayback,
}

class RatingService {
  static const _ratingKey = AppConfig.ratingStatusKey;
  static const _lastPromptKey = AppConfig.lastRatingPromptKey;
  static const _firstLaunchKey = 'afro_first_launch_ms';
  static const _savedCountKey = 'afro_saved_recordings_for_rating';
  static const _promptIntervalMs = 10 * 24 * 60 * 60 * 1000;
  static const _timeInAppMs = 5 * 60 * 1000;
  static const _recordingMilestone = 2;

  Future<void> ensureFirstLaunchRecorded() async {
    final prefs = await SharedPreferences.getInstance();
    if (!prefs.containsKey(_firstLaunchKey)) {
      await prefs.setInt(
        _firstLaunchKey,
        DateTime.now().millisecondsSinceEpoch,
      );
    }
  }

  Future<int> recordSavedRecording() async {
    final prefs = await SharedPreferences.getInstance();
    final count = (prefs.getInt(_savedCountKey) ?? 0) + 1;
    await prefs.setInt(_savedCountKey, count);
    return count;
  }

  Future<bool> shouldShowRatingPrompt() async {
    final prefs = await SharedPreferences.getInstance();
    final status = prefs.getString(_ratingKey);

    if (status == 'rated') return false;

    if (status == 'dismissed') {
      final lastPrompt = prefs.getString(_lastPromptKey);
      if (lastPrompt != null) {
        final nextPrompt = int.parse(lastPrompt) + _promptIntervalMs;
        if (DateTime.now().millisecondsSinceEpoch < nextPrompt) {
          return false;
        }
      }
    }

    return true;
  }

  Future<bool> shouldShowForTrigger(RatingPromptTrigger trigger) async {
    if (!await shouldShowRatingPrompt()) return false;

    final prefs = await SharedPreferences.getInstance();

    switch (trigger) {
      case RatingPromptTrigger.timeInApp:
        final first = prefs.getInt(_firstLaunchKey);
        if (first == null) return false;
        return DateTime.now().millisecondsSinceEpoch - first >= _timeInAppMs;
      case RatingPromptTrigger.recordingSaved:
        return (prefs.getInt(_savedCountKey) ?? 0) >= _recordingMilestone;
      case RatingPromptTrigger.recordingPlayback:
        return true;
    }
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
