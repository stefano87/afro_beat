import '../data/beats_data.dart';

class SavedRecording {
  final String id;
  final String filePath;
  final String beatName;
  final String? beatUrl;
  final String title;
  final String durationLabel;
  final DateTime createdAt;
  final double mixBeatVolume;
  final double mixVoiceVolume;

  const SavedRecording({
    required this.id,
    required this.filePath,
    required this.beatName,
    this.beatUrl,
    required this.title,
    required this.durationLabel,
    required this.createdAt,
    this.mixBeatVolume = 0.65,
    this.mixVoiceVolume = 1.0,
  });

  String get displayName => title.isNotEmpty ? title : beatName;

  /// Beat URL for dual-track mix (saved or resolved from beat name).
  String? get mixBeatUrl => beatUrl ?? resolveBeatUrlByName(beatName);

  bool get canMix => mixBeatUrl != null && mixBeatUrl!.isNotEmpty;

  SavedRecording copyWith({
    String? title,
    String? filePath,
    double? mixBeatVolume,
    double? mixVoiceVolume,
  }) {
    return SavedRecording(
      id: id,
      filePath: filePath ?? this.filePath,
      beatName: beatName,
      beatUrl: beatUrl,
      title: title ?? this.title,
      durationLabel: durationLabel,
      createdAt: createdAt,
      mixBeatVolume: mixBeatVolume ?? this.mixBeatVolume,
      mixVoiceVolume: mixVoiceVolume ?? this.mixVoiceVolume,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'filePath': filePath,
        'beatName': beatName,
        if (beatUrl != null) 'beatUrl': beatUrl,
        'title': title,
        'durationLabel': durationLabel,
        'createdAtMs': createdAt.millisecondsSinceEpoch,
        'mixBeatVolume': mixBeatVolume,
        'mixVoiceVolume': mixVoiceVolume,
      };

  factory SavedRecording.fromJson(Map<String, dynamic> json) {
    final beatName = json['beatName'] as String? ?? 'Recording';
    return SavedRecording(
      id: json['id'] as String,
      filePath: json['filePath'] as String,
      beatName: beatName,
      beatUrl: json['beatUrl'] as String?,
      title: json['title'] as String? ?? beatName,
      durationLabel: json['durationLabel'] as String? ?? '',
      createdAt: DateTime.fromMillisecondsSinceEpoch(
        json['createdAtMs'] as int,
      ),
      mixBeatVolume: (json['mixBeatVolume'] as num?)?.toDouble() ?? 0.65,
      mixVoiceVolume: (json['mixVoiceVolume'] as num?)?.toDouble() ?? 1.0,
    );
  }
}
