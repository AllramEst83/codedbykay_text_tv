import 'dart:convert';

/// The typeface of the teletext page.
enum PageFont {
  /// Press Start 2P: a square pixel face, which the page stretches upright.
  pixel,

  /// Bedstead: a font drawn after the real teletext character generator, tall
  /// and narrow as on a 1980s television.
  bedstead,
}

/// Which typeface the teletext page is drawn in. Read from disk, so decoding
/// is tolerant: anything unreadable is the pixel face the app started with.
class PageFontSettings {
  const PageFontSettings({this.font = PageFont.pixel});

  final PageFont font;

  static const PageFontSettings defaults = PageFontSettings();

  PageFontSettings copyWith({PageFont? font}) =>
      PageFontSettings(font: font ?? this.font);

  factory PageFontSettings.decode(String? source) {
    if (source == null) return defaults;
    final Object? json;
    try {
      json = jsonDecode(source);
    } on FormatException {
      return defaults;
    }
    if (json is! Map<String, Object?>) return defaults;
    return PageFontSettings(
      font: PageFont.values.asNameMap()[json['font']] ?? PageFont.pixel,
    );
  }

  String encode() => jsonEncode(<String, Object?>{'font': font.name});

  @override
  bool operator ==(Object other) =>
      other is PageFontSettings && other.font == font;

  @override
  int get hashCode => font.hashCode;
}
