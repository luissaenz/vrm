class TeleprompterPrefs {
  final double fontSize;
  final double readingSpeed;
  final double brightness;

  TeleprompterPrefs({
    required this.fontSize,
    required this.readingSpeed,
    required this.brightness,
  });

  factory TeleprompterPrefs.defaults() => TeleprompterPrefs(
        fontSize: 24.0,
        readingSpeed: 150.0,
        brightness: 0.8,
      );

  factory TeleprompterPrefs.fromMap(Map<String, dynamic> map) {
    return TeleprompterPrefs(
      fontSize: (map['fontSize'] as num?)?.toDouble() ?? 24.0,
      readingSpeed: (map['readingSpeed'] as num?)?.toDouble() ?? 150.0,
      brightness: (map['brightness'] as num?)?.toDouble() ?? 0.8,
    );
  }

  Map<String, dynamic> toMap() => {
        'fontSize': fontSize,
        'readingSpeed': readingSpeed,
        'brightness': brightness,
      };
}