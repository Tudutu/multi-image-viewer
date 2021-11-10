import 'dart:ui';

class MediaViewFileInfo {
  final String mimeType;
  final String filePath;
  final String? name;
  final Color backgroundColor;
  final Object? heroTag;
  final Duration? audioDuration;

  MediaViewFileInfo({
    required this.mimeType,
    required this.filePath,
    this.name,
    this.backgroundColor = const Color(0xFF000000),
    this.heroTag,
    this.audioDuration,
  });
}
