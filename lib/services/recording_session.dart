import 'dart:async';
import 'dart:io';

import 'package:audio_session/audio_session.dart';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';

import '../models/beat.dart';
import 'admob_service.dart';
import 'beat_audio_service.dart';
import 'saved_recordings_service.dart';

class RecordingSession extends ChangeNotifier {
  static const maxRecordingTime = 240;
  static const _recordingBeatVolume = 0.55;

  final AudioRecorder _recorder = AudioRecorder();

  final BeatAudioService beatAudio;
  final AdMobService adMob;
  final SavedRecordingsService savedRecordings;

  Beat? selectedBeat;
  bool showCountdown = false;

  /// True while the beat is loading before recording starts.
  bool isPreparing = false;

  bool isStopping = false;
  int countdownNumber = 3;
  int recordingTime = 0;
  String recordedDuration = '';
  String? recordingFilePath;
  String? savedFilePath;
  String? savedRecordingId;
  String recordingTitle = '';
  String? currentFileName;
  bool isRecordingDownloaded = false;
  bool playRecordedAudio = false;
  bool hasRecording = false;
  bool recordingFailed = false;

  bool _isRecordingActive = false;
  Timer? _countdownTimer;
  Timer? _recordingTimer;
  StreamSubscription<PlayerState>? _playerSub;

  // WAV = AudioRecord on Android. Ionic order: mic first, then beat in speaker.
  static const _recordConfig = RecordConfig(
    encoder: AudioEncoder.wav,
    sampleRate: 44100,
    numChannels: 1,
    echoCancel: false,
    autoGain: false,
    noiseSuppress: false,
    audioInterruption: AudioInterruptionMode.none,
    androidConfig: AndroidRecordConfig(
      speakerphone: true,
      manageBluetooth: false,
      audioSource: AndroidAudioSource.mic,
    ),
  );

  RecordingSession({
    required this.beatAudio,
    required this.adMob,
    required this.savedRecordings,
  });

  int get remainingTime => maxRecordingTime - recordingTime;
  bool get isAnyBeatRecording => _isRecordingActive;

  String formatTime(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  /// Mic + speaker at the same time (Ionic: HTML audio + VoiceRecorder).
  Future<void> _configureSessionForRecording() async {
    if (kIsWeb) return;
    final session = await AudioSession.instance;
    await session.configure(
      const AudioSessionConfiguration(
        avAudioSessionCategory: AVAudioSessionCategory.playAndRecord,
        avAudioSessionCategoryOptions:
            AVAudioSessionCategoryOptions.defaultToSpeaker,
        avAudioSessionMode: AVAudioSessionMode.defaultMode,
        androidAudioAttributes: AndroidAudioAttributes(
          contentType: AndroidAudioContentType.music,
          usage: AndroidAudioUsage.media,
        ),
        androidAudioFocusGainType: AndroidAudioFocusGainType.gain,
        androidWillPauseWhenDucked: false,
      ),
    );
    await session.setActive(true);
  }

  Future<void> _configureSessionForPlayback() async {
    if (kIsWeb) return;
    final session = await AudioSession.instance;
    await session.configure(const AudioSessionConfiguration.music());
  }

  Future<bool> checkAndRequestPermission() async {
    if (kIsWeb) return true;
    final status = await Permission.microphone.status;
    if (status.isGranted) return true;
    final result = await Permission.microphone.request();
    return result.isGranted;
  }

  void _resetRecordingOutput() {
    hasRecording = false;
    recordingFailed = false;
    isRecordingDownloaded = false;
    playRecordedAudio = false;
    recordedDuration = '';
    recordingFilePath = null;
    savedFilePath = null;
    currentFileName = null;
  }

  Future<void> startRecording(Beat beat) async {
    if (_isRecordingActive || showCountdown || isPreparing) return;

    final granted = await checkAndRequestPermission();
    if (!granted) {
      debugPrint('Microphone permission not granted');
      return;
    }

    await beatAudio.stop();
    _resetRecordingOutput();

    showCountdown = true;
    countdownNumber = 3;
    selectedBeat = beat.copyWith(isRecording: false);
    notifyListeners();

    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) async {
      countdownNumber--;
      notifyListeners();

      if (countdownNumber > 0) return;

      timer.cancel();
      showCountdown = false;
      isPreparing = true;
      notifyListeners();

      try {
        await _configureSessionForRecording();

        final dir = await getTemporaryDirectory();
        currentFileName =
            'recording_${DateTime.now().millisecondsSinceEpoch}.wav';
        recordingFilePath = '${dir.path}/$currentFileName';

        // Mic + beat together (Ionic: recorder then playBeat — no blocking wait).
        await _recorder.start(_recordConfig, path: recordingFilePath!);

        final beatStarted = await beatAudio.playBeatForRecording(
          beat,
          volume: _recordingBeatVolume,
        );
        if (!beatStarted) {
          debugPrint('Beat playback did not start — recording voice only');
        }

        _beginActiveRecording(beat);
      } catch (e) {
        debugPrint('Start recording error: $e');
        await _abortRecordingStart();
      }
    });
  }

  void _beginActiveRecording(Beat beat) {
    isPreparing = false;
    _isRecordingActive = true;
    recordingTime = 0;
    selectedBeat = beat.copyWith(isRecording: true);
    notifyListeners();

    _recordingTimer?.cancel();
    _recordingTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!_isRecordingActive) return;
      recordingTime++;
      notifyListeners();
      if (recordingTime >= maxRecordingTime) stopRecording();
    });
  }

  Future<void> _abortRecordingStart() async {
    isPreparing = false;
    _isRecordingActive = false;
    _recordingTimer?.cancel();
    try {
      await beatAudio.stop();
      if (await _recorder.isRecording()) {
        await _recorder.stop();
      }
    } catch (_) {}
    selectedBeat = null;
    showCountdown = false;
    notifyListeners();
  }

  Future<void> stopRecording([Beat? beat]) async {
    if (!_isRecordingActive || isStopping) return;

    isStopping = true;
    _isRecordingActive = false;
    _recordingTimer?.cancel();
    _countdownTimer?.cancel();
    recordedDuration = formatTime(recordingTime);
    notifyListeners();

    try {
      await beatAudio.stop();
      await beatAudio.resetVolume();

      if (await _recorder.isRecording()) {
        final path = await _recorder.stop();
        if (path != null && path.isNotEmpty) {
          recordingFilePath = path;
        }
      }

      // Give OS time to flush and close the WAV file.
      await Future.delayed(const Duration(milliseconds: 800));

      if (recordingFilePath != null) {
        final file = File(recordingFilePath!);
        if (await file.exists()) {
          final size = await file.length();
          // WAV header = 44 bytes; 1 second mono 44100Hz = ~88 KB.
          // Require at least 50 KB so we know something was captured.
          hasRecording = size > 50000;
          recordingFailed = !hasRecording;
          debugPrint(
            'Recording: ${size ~/ 1024} KB | $recordedDuration | $recordingFilePath',
          );
        } else {
          recordingFailed = true;
          debugPrint('Recording file not found at $recordingFilePath');
        }
      } else {
        recordingFailed = true;
      }

      final activeBeat = beat ?? selectedBeat;
      if (activeBeat != null) {
        selectedBeat = activeBeat.copyWith(isRecording: false);
      }

      if (hasRecording && recordingFilePath != null) {
        await _persistToLibrary(activeBeat?.name ?? 'Beat');
      }
    } catch (e) {
      debugPrint('Stop recording error: $e');
      recordingFailed = true;
    } finally {
      isStopping = false;
      notifyListeners();
    }

    if (hasRecording) {
      await adMob.showInterstitial();
    }
  }

  Future<void> _persistToLibrary(String beatName) async {
    if (recordingFilePath == null) return;
    if (isRecordingDownloaded && savedFilePath != null) return;

    final entry = await savedRecordings.add(
      sourcePath: recordingFilePath!,
      beatName: beatName,
      durationLabel: recordedDuration,
    );
    if (entry != null) {
      savedFilePath = entry.filePath;
      savedRecordingId = entry.id;
      recordingTitle = entry.displayName;
      isRecordingDownloaded = true;
      notifyListeners();
    }
  }

  Future<bool> renameSavedRecording(String title) async {
    final trimmed = title.trim();
    if (trimmed.isEmpty || savedRecordingId == null) return false;

    final ok = await savedRecordings.rename(savedRecordingId!, trimmed);
    if (ok) {
      recordingTitle = trimmed;
      notifyListeners();
    }
    return ok;
  }

  /// Re-save if auto-save failed (manual retry from panel).
  Future<void> saveRecording() async {
    await _persistToLibrary(selectedBeat?.name ?? 'Beat');
    if (!isRecordingDownloaded) {
      throw Exception('Recording file not found');
    }
  }

  /// Play the recording through the BeatAudioService player.
  /// Returns true if playback started successfully.
  Future<bool> playRecording() async {
    final path = isRecordingDownloaded && savedFilePath != null
        ? savedFilePath!
        : recordingFilePath;

    if (path == null) {
      debugPrint('playRecording: no path');
      return false;
    }

    final file = File(path);
    if (!await file.exists()) {
      debugPrint('playRecording: file not found at $path');
      return false;
    }

    final size = await file.length();
    debugPrint('playRecording: ${size ~/ 1024} KB at $path');

    try {
      await _configureSessionForPlayback();
      final ok = await beatAudio.playLocalFile(path);
      if (!ok) return false;

      _playerSub?.cancel();
      _playerSub = beatAudio.playerStateStream.listen((state) {
        if (state.processingState == ProcessingState.completed) {
          playRecordedAudio = false;
          notifyListeners();
        }
      });

      playRecordedAudio = true;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('playRecording error: $e');
      playRecordedAudio = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> stopPlayRecording() async {
    await beatAudio.stop();
    playRecordedAudio = false;
    notifyListeners();
  }

  void closeSelectedBeat() {
    if (_isRecordingActive || isPreparing) return;
    selectedBeat = null;
    _resetRecordingOutput();
    recordingTime = 0;
    notifyListeners();
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _recordingTimer?.cancel();
    _playerSub?.cancel();
    _recorder.dispose();
    super.dispose();
  }
}
