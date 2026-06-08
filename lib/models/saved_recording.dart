class SavedRecording {
  final String id;
  final String filePath;
  final String beatName;
  final String title;
  final String durationLabel;
  final DateTime createdAt;

  const SavedRecording({
    required this.id,
    required this.filePath,
    required this.beatName,
    required this.title,
    required this.durationLabel,
    required this.createdAt,
  });

  String get displayName => title.isNotEmpty ? title : beatName;

  SavedRecording copyWith({String? title}) {
    return SavedRecording(
      id: id,
      filePath: filePath,
      beatName: beatName,
      title: title ?? this.title,
      durationLabel: durationLabel,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'filePath': filePath,
        'beatName': beatName,
        'title': title,
        'durationLabel': durationLabel,
        'createdAtMs': createdAt.millisecondsSinceEpoch,
      };

  factory SavedRecording.fromJson(Map<String, dynamic> json) {
    final beatName = json['beatName'] as String? ?? 'Recording';
    return SavedRecording(
      id: json['id'] as String,
      filePath: json['filePath'] as String,
      beatName: beatName,
      title: json['title'] as String? ?? beatName,
      durationLabel: json['durationLabel'] as String? ?? '',
      createdAt: DateTime.fromMillisecondsSinceEpoch(
        json['createdAtMs'] as int,
      ),
    );
  }
}
