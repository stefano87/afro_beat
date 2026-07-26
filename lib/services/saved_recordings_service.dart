import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../config/app_config.dart';
import '../models/saved_recording.dart';

class SavedRecordingsService extends ChangeNotifier {
  static const _prefsKey = AppConfig.savedRecordingsKey;

  List<SavedRecording> _recordings = [];
  String? _playingId;

  List<SavedRecording> get recordings => List.unmodifiable(_recordings);
  String? get playingId => _playingId;
  bool isPlaying(String id) => _playingId == id;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefsKey);
    if (raw == null || raw.isEmpty) {
      _recordings = [];
      notifyListeners();
      return;
    }

    final list = (jsonDecode(raw) as List)
        .map((e) => SavedRecording.fromJson(e as Map<String, dynamic>))
        .toList();

    final valid = <SavedRecording>[];
    for (final r in list) {
      if (await File(r.filePath).exists()) {
        valid.add(r);
      }
    }

    valid.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    _recordings = valid;
    if (_playingId != null && !valid.any((r) => r.id == _playingId)) {
      _playingId = null;
    }
    await _persistIndex();
    notifyListeners();
  }

  Future<SavedRecording?> add({
    required String sourcePath,
    required String beatName,
    required String durationLabel,
    String? title,
    String? beatUrl,
    double mixBeatVolume = 0.65,
    double mixVoiceVolume = 1.0,
  }) async {
    final source = File(sourcePath);
    if (!await source.exists()) return null;

    final docs = await getApplicationDocumentsDirectory();
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    final destName = 'recording_$id.wav';
    final destPath = '${docs.path}/$destName';

    await source.copy(destPath);

    final entry = SavedRecording(
      id: id,
      filePath: destPath,
      beatName: beatName,
      beatUrl: beatUrl,
      title: title?.trim().isNotEmpty == true ? title!.trim() : beatName,
      durationLabel: durationLabel,
      createdAt: DateTime.now(),
      mixBeatVolume: mixBeatVolume,
      mixVoiceVolume: mixVoiceVolume,
    );

    _recordings.insert(0, entry);
    await _persistIndex();
    notifyListeners();
    return entry;
  }

  Future<void> delete(String id) async {
    final entry = _recordings.where((r) => r.id == id).firstOrNull;
    if (entry == null) return;

    try {
      final file = File(entry.filePath);
      if (await file.exists()) await file.delete();
    } catch (e) {
      debugPrint('Delete recording file error: $e');
    }

    _recordings.removeWhere((r) => r.id == id);
    if (_playingId == id) _playingId = null;
    await _persistIndex();
    notifyListeners();
  }

  void setPlayingId(String? id) {
    _playingId = id;
    notifyListeners();
  }

  Future<void> updateMixLevels({
    required String id,
    required double mixBeatVolume,
    required double mixVoiceVolume,
  }) async {
    final index = _recordings.indexWhere((r) => r.id == id);
    if (index < 0) return;

    _recordings[index] = _recordings[index].copyWith(
      mixBeatVolume: mixBeatVolume.clamp(0.0, 1.0),
      mixVoiceVolume: mixVoiceVolume.clamp(0.0, 1.0),
    );
    await _persistIndex();
    notifyListeners();
  }

  Future<bool> overwriteWithMix({
    required String id,
    required String mixedFilePath,
    required double mixBeatVolume,
    required double mixVoiceVolume,
    String? title,
  }) async {
    final index = _recordings.indexWhere((r) => r.id == id);
    if (index < 0) return false;

    final old = _recordings[index];
    if (old.filePath != mixedFilePath) {
      try {
        final previous = File(old.filePath);
        if (await previous.exists()) await previous.delete();
      } catch (e) {
        debugPrint('overwriteWithMix delete old file: $e');
      }
    }

    final trimmedTitle = title?.trim();
    _recordings[index] = old.copyWith(
      filePath: mixedFilePath,
      title: trimmedTitle != null && trimmedTitle.isNotEmpty
          ? trimmedTitle
          : old.title,
      mixBeatVolume: mixBeatVolume.clamp(0.0, 1.0),
      mixVoiceVolume: mixVoiceVolume.clamp(0.0, 1.0),
    );
    await _persistIndex();
    notifyListeners();
    return true;
  }

  Future<SavedRecording?> addMixedCopy({
    required SavedRecording source,
    required String mixedFilePath,
    required double mixBeatVolume,
    required double mixVoiceVolume,
    String? title,
  }) async {
    final mixed = File(mixedFilePath);
    if (!await mixed.exists()) return null;

    final docs = await getApplicationDocumentsDirectory();
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    final destPath = '${docs.path}/recording_$id.wav';
    await mixed.copy(destPath);

    final trimmedTitle = title?.trim();
    final entry = SavedRecording(
      id: id,
      filePath: destPath,
      beatName: source.beatName,
      beatUrl: source.beatUrl,
      title: trimmedTitle != null && trimmedTitle.isNotEmpty
          ? trimmedTitle
          : '${source.displayName} (mix)',
      durationLabel: source.durationLabel,
      createdAt: DateTime.now(),
      mixBeatVolume: mixBeatVolume.clamp(0.0, 1.0),
      mixVoiceVolume: mixVoiceVolume.clamp(0.0, 1.0),
    );

    _recordings.insert(0, entry);
    await _persistIndex();
    notifyListeners();
    return entry;
  }

  Future<bool> rename(String id, String title) async {
    final trimmed = title.trim();
    if (trimmed.isEmpty) return false;

    final index = _recordings.indexWhere((r) => r.id == id);
    if (index < 0) return false;

    _recordings[index] = _recordings[index].copyWith(title: trimmed);
    await _persistIndex();
    notifyListeners();
    return true;
  }

  Future<void> _persistIndex() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = _recordings.map((r) => r.toJson()).toList();
    await prefs.setString(_prefsKey, jsonEncode(jsonList));
  }
}
