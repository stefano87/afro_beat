import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../config/app_config.dart';
import '../models/beat.dart';

class FavoritesService extends ChangeNotifier {
  static const _storageKey = AppConfig.favoritesStorageKey;

  List<Beat> _favorites = [];

  List<Beat> get favorites => List.unmodifiable(_favorites);

  Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final value = prefs.getString(_storageKey);
      if (value != null) {
        final list = (jsonDecode(value) as List)
            .map((e) => Beat.fromJson(e as Map<String, dynamic>))
            .toList();
        _favorites = list;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('[FavoritesService] load error: $e');
      _favorites = [];
    }
  }

  bool isFavorite(Beat beat) => _favorites.any((f) => f.id == beat.id);

  Future<void> toggleFavorite(Beat beat) async {
    if (isFavorite(beat)) {
      _favorites = _favorites.where((f) => f.id != beat.id).toList();
    } else {
      _favorites = [..._favorites, beat.copyWith(isPlaying: false, isRecording: false)];
    }
    await _save();
    notifyListeners();
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonValue = jsonEncode(_favorites.map((b) => b.toJson()).toList());
    await prefs.setString(_storageKey, jsonValue);
  }
}
