import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';

import '../data/radio_stations_data.dart';
import '../models/radio_station.dart';

class RadioService extends ChangeNotifier {
  final AudioPlayer _player = AudioPlayer();
  int? _currentStationIndex;
  double _volume = 0.7;
  Timer? _adTimer;

  static const _adInterval = Duration(minutes: 3);

  RadioService() {
    _player.setVolume(_volume);
    _player.playerStateStream.listen((_) => notifyListeners());
  }

  List<RadioStation> get stations => radioStations;
  int? get currentStationIndex => _currentStationIndex;
  RadioStation? get currentStation =>
      _currentStationIndex != null ? stations[_currentStationIndex!] : null;
  bool get isPlaying => _player.playing;
  double get volume => _volume;

  void startAdTimer(Future<void> Function() onShowAd) {
    stopAdTimer();
    _adTimer = Timer.periodic(_adInterval, (_) => onShowAd());
  }

  void stopAdTimer() {
    _adTimer?.cancel();
    _adTimer = null;
  }

  Future<void> selectStation(int index) async {
    if (_currentStationIndex == index) {
      await togglePlay();
      return;
    }

    _currentStationIndex = index;
    final station = stations[index];

    try {
      await _player.setUrl(station.url);
      await _player.play();
      notifyListeners();
    } catch (e) {
      debugPrint('Radio play error: $e');
      rethrow;
    }
  }

  Future<void> togglePlay() async {
    if (currentStation == null) {
      if (stations.isNotEmpty) {
        await selectStation(0);
      }
      return;
    }

    if (_player.playing) {
      await _player.pause();
    } else {
      await _player.play();
    }
    notifyListeners();
  }

  Future<void> previousStation() async {
    if (_currentStationIndex == null) return;
    final prev = _currentStationIndex! <= 0
        ? stations.length - 1
        : _currentStationIndex! - 1;
    await selectStation(prev);
  }

  Future<void> nextStation() async {
    if (_currentStationIndex == null) return;
    final next = _currentStationIndex! >= stations.length - 1
        ? 0
        : _currentStationIndex! + 1;
    await selectStation(next);
  }

  Future<void> setVolume(double value) async {
    _volume = value;
    await _player.setVolume(value);
    notifyListeners();
  }

  Future<void> pauseForAd() async {
    if (_player.playing) await _player.pause();
  }

  Future<void> resumeAfterAd() async {
    if (currentStation != null && !_player.playing) {
      try {
        await _player.play();
      } catch (e) {
        debugPrint('Resume radio error: $e');
      }
    }
  }

  @override
  void dispose() {
    stopAdTimer();
    _player.dispose();
    super.dispose();
  }
}
