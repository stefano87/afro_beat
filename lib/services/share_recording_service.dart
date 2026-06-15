import 'dart:io';

import 'package:share_plus/share_plus.dart';

import '../config/app_config.dart';
import '../models/saved_recording.dart';

class ShareRecordingService {
  ShareRecordingService._();

  static String shareMessage(SavedRecording recording) {
    return '🎤 Listen to my track made with ${AppConfig.appTitle}! 🎶\n\n'
        '🎵 "${recording.displayName}"\n'
        '🔥 Beat: ${recording.beatName}\n\n'
        'Create your own Afro beats for free — get the app on Google Play:\n'
        '${AppConfig.playStoreWebUrl}';
  }

  static Future<void> shareRecording(SavedRecording recording) async {
    final file = File(recording.filePath);
    if (!await file.exists()) {
      throw StateError('Recording file not found');
    }

    await Share.shareXFiles(
      [
        XFile(
          recording.filePath,
          mimeType: 'audio/wav',
          name: '${recording.displayName}.wav',
        ),
      ],
      text: shareMessage(recording),
      subject: 'My track — ${AppConfig.appTitle}',
    );
  }
}
