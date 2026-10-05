import 'dart:convert';

/// The reader's colour schemes, by the name they are saved under.
enum ReaderTheme {
  /// Eggshell text on black.
  black,

  /// Light grey text on dark grey.
  grey,

  /// Dark brown text on beige.
  beige,

  /// Black text on white.
  paper,

  /// Yellow on black, links in white.
  contrast,
}

/// Text sizes the reader steps through, in logical pixels before the phone's
/// own font-size setting is applied on top.
const List<double> readerTextSizes = <double>[14, 16, 18, 20, 24, 28, 32, 40];

/// The size a fresh install starts at: an index into [readerTextSizes].
const int readerDefaultSize = 2;

/// Whether the viewer is in reader mode and how the reader looks. Read from
/// disk, so decoding is tolerant: a bad field is replaced by its default.
class ReaderSettings {
  const ReaderSettings({
    this.enabled = false,
    this.theme = ReaderTheme.black,
    this.size = readerDefaultSize,
  });

  /// Pages show as reader text instead of the teletext grid.
  final bool enabled;
  final ReaderTheme theme;

  /// An index into [readerTextSizes].
  final int size;

  double get fontSize => readerTextSizes[size];

  ReaderSettings copyWith({bool? enabled, ReaderTheme? theme, int? size}) =>
      ReaderSettings(
        enabled: enabled ?? this.enabled,
        theme: theme ?? this.theme,
        size: size ?? this.size,
      );

  factory ReaderSettings.decode(String? source) {
    if (source == null) return const ReaderSettings();
    final Object? json;
    try {
      json = jsonDecode(source);
    } on FormatException {
      return const ReaderSettings();
    }
    if (json is! Map<String, Object?>) return const ReaderSettings();
    final Object? enabled = json['enabled'];
    final Object? theme = json['theme'];
    final Object? size = json['size'];
    return ReaderSettings(
      enabled: enabled is bool && enabled,
      theme: ReaderTheme.values.asNameMap()[theme] ?? ReaderTheme.black,
      size: size is int && size >= 0 && size < readerTextSizes.length
          ? size
          : readerDefaultSize,
    );
  }

  String encode() => jsonEncode(<String, Object?>{
    'enabled': enabled,
    'theme': theme.name,
    'size': size,
  });

  @override
  bool operator ==(Object other) =>
      other is ReaderSettings &&
      other.enabled == enabled &&
      other.theme == theme &&
      other.size == size;

  @override
  int get hashCode => Object.hash(enabled, theme, size);
}
