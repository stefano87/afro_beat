import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Plays saved voice + original beat as separate tracks with adjustable levels.
class MixPlaybackService extends ChangeNotifier {
  static const _beatVolKey = 'afro_mix_beat_volume';
  static const _voiceVolKey = 'afro_mix_voice_volume';
  static const _monitorVolKey = 'afro_monitor_beat_volume';

  final AudioPlayer _voicePlayer = AudioPlayer();
  final AudioPlayer _beatPlayer = AudioPlayer();

  double _beatVolume = 0.65;
  double _voiceVolume = 1.0;
  double _monitorBeatVolume = 0.4;
  bool _playing = false;
  bool _stopping = false;
  bool _previewExtraBeat = false;
  int _playbackEpoch = 0;
  String? _activeRecordingId;
  void Function(String? recordingId)? onPlaybackEnded;

  double get beatVolume => _beatVolume;
  double get voiceVolume => _voiceVolume;
  double get monitorBeatVolume => _monitorBeatVolume;
  bool get isPlaying => _playing;
  bool get previewExtraBeat => _previewExtraBeat;
  String? get activeRecordingId => _activeRecordingId;

  MixPlaybackService() {
    void onVoiceState(PlayerState state) {
      if (_stopping || !_playing) {
        notifyListeners();
        return;
      }
      if (state.processingState == ProcessingState.completed &&
          state.playing == false) {
        unawaited(stop());
      }
      notifyListeners();
    }
    _voicePlayer.playerStateStream.listen(onVoiceState);
    _beatPlayer.playerStateStream.listen((_) {
      if (!_stopping) notifyListeners();
    });
  }

  Future<void> loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    _beatVolume = prefs.getDouble(_beatVolKey) ?? 0.65;
    _voiceVolume = prefs.getDouble(_voiceVolKey) ?? 1.0;
    _monitorBeatVolume = prefs.getDouble(_monitorVolKey) ?? 0.4;
    notifyListeners();
  }

  Future<void> setBeatVolume(double value) async {
    _beatVolume = value.clamp(0.0, 1.0);
    await _beatPlayer.setVolume(_beatVolume);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_beatVolKey, _beatVolume);
    notifyListeners();
  }

  Future<void> setVoiceVolume(double value) async {
    _voiceVolume = value.clamp(0.0, 1.0);
    await _voicePlayer.setVolume(_voiceVolume);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_voiceVolKey, _voiceVolume);
    notifyListeners();
  }

  Future<void> setMonitorBeatVolume(double value) async {
    _monitorBeatVolume = value.clamp(0.0, 1.0);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_monitorVolKey, _monitorBeatVolume);
    notifyListeners();
  }

  void setPreviewExtraBeat(bool value) {
    _previewExtraBeat = value;
    notifyListeners();
  }

  Future<bool> play({
    required String recordingId,
    required String voicePath,
    required String beatUrl,
    double? beatVolume,
    double? voiceVolume,
    bool includeSeparateBeat = false,
  }) async {
    if (beatVolume != null) _beatVolume = beatVolume.clamp(0.0, 1.0);
    if (voiceVolume != null) _voiceVolume = voiceVolume.clamp(0.0, 1.0);
    final playBeat = includeSeparateBeat || _previewExtraBeat;

    try {
      await stop(notifyEnded: false);
      final epoch = _playbackEpoch;
      await _voicePlayer.setFilePath(voicePath);
      await _voicePlayer.setVolume(_voiceVolume);

      if (playBeat) {
        await _beatPlayer.setUrl(beatUrl);
        await _beatPlayer.setVolume(_beatVolume);
        await _beatPlayer.setLoopMode(LoopMode.one);
      } else {
        await _beatPlayer.stop();
      }

      if (epoch != _playbackEpoch) return false;

      _activeRecordingId = recordingId;
      _playing = true;
      notifyListeners();

      unawaited(_voicePlayer.play());
      if (playBeat) {
        unawaited(_beatPlayer.play());
      }
      return true;
    } catch (e) {
      debugPrint('MixPlaybackService.play error: $e');
      await stop();
      return false;
    }
  }

  Future<void> stop({bool notifyEnded = true}) async {
    if (_stopping) return;
    _stopping = true;
    _playbackEpoch++;
    final endedId = _activeRecordingId;
    _playing = false;
    _activeRecordingId = null;
    notifyListeners();

    try {
      await Future.wait([
        _voicePlayer.stop(),
        _beatPlayer.stop(),
      ]);
    } catch (e) {
      debugPrint('MixPlaybackService.stop error: $e');
    } finally {
      _stopping = false;
      notifyListeners();
      if (notifyEnded) {
        onPlaybackEnded?.call(endedId);
      }
    }
  }

  bool isPlayingRecording(String id) =>
      _activeRecordingId == id && _playing;

  bool isActiveRecording(String id) => _activeRecordingId == id;

  @override
  void dispose() {
    _voicePlayer.dispose();
    _beatPlayer.dispose();
    super.dispose();
  }
}
