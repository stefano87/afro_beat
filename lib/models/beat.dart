class Beat {
  final int id;
  final String name;
  final String url;
  bool isPlaying;
  bool isRecording;

  Beat({
    required this.id,
    required this.name,
    required this.url,
    this.isPlaying = false,
    this.isRecording = false,
  });

  Beat copyWith({
    int? id,
    String? name,
    String? url,
    bool? isPlaying,
    bool? isRecording,
  }) {
    return Beat(
      id: id ?? this.id,
      name: name ?? this.name,
      url: url ?? this.url,
      isPlaying: isPlaying ?? this.isPlaying,
      isRecording: isRecording ?? this.isRecording,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'url': url,
        'isRecording': false,
      };

  factory Beat.fromJson(Map<String, dynamic> json) => Beat(
        id: json['id'] as int,
        name: json['name'] as String,
        url: json['url'] as String,
      );
}
