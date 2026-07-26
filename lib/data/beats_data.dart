import '../config/app_config.dart';
import '../models/beat.dart';

List<Beat> generateBeats() {
  return [..._generateTrapBeats(), ..._generateAfroBeats()];
}

List<Beat> _generateTrapBeats() {
  final baseUrl = AppConfig.beatsCdnBaseUrl;
  final prefix = AppConfig.freeBeatNamePrefix;
  final beats = <Beat>[
    Beat(
      id: 0,
      name: '$prefix 1',
      url: '$baseUrl${AppConfig.freeBeatFileName}',
    ),
  ];

  for (var n = 2; n <= AppConfig.freeBeatCount; n++) {
    beats.add(
      Beat(
        id: n - 1,
        name: '$prefix $n',
        url: '${baseUrl}beat$n.mp3',
      ),
    );
  }

  return beats;
}

List<Beat> _generateAfroBeats() {
  final baseUrl = AppConfig.afroCdnBaseUrl;
  final prefix = AppConfig.afroBeatNamePrefix;
  final startId = AppConfig.freeBeatCount;

  return List.generate(AppConfig.afroBeatCount, (i) {
    final number = i + 1;
    return Beat(
      id: startId + i,
      name: '$prefix $number',
      url: '${baseUrl}afro$number.mp3',
    );
  });
}

/// Finds the beat stream URL from a saved recording name (for older saves).
String? resolveBeatUrlByName(String beatName) {
  for (final beat in generateBeats()) {
    if (beat.name == beatName) return beat.url;
  }
  return null;
}
