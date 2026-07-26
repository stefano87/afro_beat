import 'dart:async';

import 'package:audio_session/audio_session.dart';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';

import '../models/beat.dart';

class BeatAudioService extends ChangeNotifier {
  final AudioPlayer _player = AudioPlayer();
  Beat? _currentBeat;
  double _volume = 1.0;
  bool _sessionReady = false;

  Beat? get currentBeat => _currentBeat;
  bool get isPlaying => _player.playing;
  double get volume => _volume;

  BeatAudioService() {
    _player.playerStateStream.listen((state) {
      if (state.processingState == ProcessingState.completed) {
        _clearPlayingState();
      }
      notifyListeners();
    });
  }

  Future<void> _ensurePlaybackSession() async {
    if (kIsWeb || _sessionReady) return;

    final session = await AudioSession.instance;
    await session.configure(
      const AudioSessionConfiguration(
        avAudioSessionCategory: AVAudioSessionCategory.playback,
        avAudioSessionMode: AVAudioSessionMode.defaultMode,
        androidAudioAttributes: AndroidAudioAttributes(
          contentType: AndroidAudioContentType.music,
          usage: AndroidAudioUsage.media,
        ),
        androidAudioFocusGainType: AndroidAudioFocusGainType.gain,
      ),
    );
    await session.setActive(true);
    _sessionReady = true;
  }

  Future<void> playBeat(Beat beat, {double? volume}) async {
    if (_currentBeat?.id == beat.id && _player.playing) {
      await stop();
      return;
    }

    if (volume != null) {
      _volume = volume;
    }

    try {
      await _ensurePlaybackSession();
      await _player.stop();
      await _player.setVolume(_volume);
      await _player.setUrl(beat.url);
      _currentBeat = beat;
      unawaited(_player.play());
      notifyListeners();
    } catch (e) {
      debugPrint('Error playing beat (${beat.url}): $e');
      _clearPlayingState();
      notifyListeners();
      rethrow;
    }
  }

  /// Beat during recording.
  /// IMPORTANT: just_audio's play() future only completes when playback
  /// ENDS/stops, so we must NOT await it or the caller hangs forever
  /// ("Loading beat..." stuck). We load the URL, fire play(), and return.
  Future<bool> playBeatForRecording(Beat beat, {double volume = 0.55}) async {
    _volume = volume;
    try {
      await _player.stop();
      await _player.setVolume(volume);
      await _player.setUrl(beat.url);
      _currentBeat = beat;
      unawaited(_player.play());
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('playBeatForRecording error (${beat.url}): $e');
      _clearPlayingState();
      notifyListeners();
      return false;
    }
  }

  Future<void> setVolume(double value) async {
    _volume = value.clamp(0.0, 1.0);
    await _player.setVolume(_volume);
    notifyListeners();
  }

  Future<void> resetVolume() async {
    _volume = 1.0;
    await _player.setVolume(_volume);
    notifyListeners();
  }

  Future<void> stop() async {
    try {
      if (_player.playing) {
        await _player.pause();
      }
      await _player.stop();
    } catch (e) {
      debugPrint('BeatAudioService.stop error: $e');
    }
    _clearPlayingState();
    notifyListeners();
  }

  /// Hard stop after recording — ensures speaker output is silenced on Android.
  Future<void> stopAfterRecording() async {
    await stop();
    if (kIsWeb) return;
    try {
      final session = await AudioSession.instance;
      await session.setActive(false);
    } catch (e) {
      debugPrint('BeatAudioService.stopAfterRecording session error: $e');
    }
  }

  /// Play a local audio file (recording playback).
  /// Returns true if playback started successfully.
  Future<bool> playLocalFile(String path) async {
    try {
      await _ensurePlaybackSession();
      await _player.stop();
      _currentBeat = null;
      await _player.setVolume(1.0);
      _volume = 1.0;
      await _player.setFilePath(path);
      unawaited(_player.play());
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('playLocalFile error: $e');
      return false;
    }
  }

  Stream<PlayerState> get playerStateStream => _player.playerStateStream;

  void _clearPlayingState() {
    _currentBeat = null;
  }

  bool isBeatPlaying(Beat beat) =>
      _currentBeat?.id == beat.id && _player.playing;

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }
}
