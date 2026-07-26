import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

class WavMixExportService {
  static const _channel = MethodChannel('com.afrobeattrap.studio/wav_mix');

  static Future<String?> exportMix({
    required String voicePath,
    required String beatUrl,
    required double voiceVolume,
    required double beatVolume,
  }) async {
    if (kIsWeb || !(Platform.isAndroid || Platform.isIOS)) return null;

    final docs = await getApplicationDocumentsDirectory();
    final outputPath =
        '${docs.path}/mix_${DateTime.now().millisecondsSinceEpoch}.wav';

    try {
      final result = await _channel.invokeMethod<String>('exportMix', {
        'voicePath': voicePath,
        'beatUrl': beatUrl,
        'outputPath': outputPath,
        'voiceVolume': voiceVolume.clamp(0.0, 1.0),
        'beatVolume': beatVolume.clamp(0.0, 1.0),
      });
      if (result == null || !await File(result).exists()) return null;
      return result;
    } on PlatformException catch (e) {
      debugPrint('WavMixExportService error: ${e.message}');
      return null;
    }
  }
}
