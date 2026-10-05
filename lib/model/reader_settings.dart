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

/// The typefaces the reader can set text in, by the name they are saved under.
enum ReaderFont {
  /// The phone's own.
  system,

  /// Atkinson Hyperlegible: made by the Braille Institute for low vision, with
  /// letters that cannot be mistaken for each other.
  atkinson,

  /// OpenDyslexic: heavy-bottomed letters, which some people with dyslexia
  /// find keep still on the line.
  dyslexic,
}

/// Text sizes the reader steps through, in logical pixels before the phone's
/// own font-size setting is applied on top.
const List<double> readerTextSizes = <double>[14, 16, 18, 20, 24, 28, 32, 40];

/// The size a fresh install starts at: an index into [readerTextSizes].
const int readerDefaultSize = 2;

/// Line heights the reader steps through, as a multiple of the text size.
/// Crowded lines tire the eye; very loose ones lose the thread of the line.
const List<double> readerLineHeights = <double>[1.25, 1.4, 1.5, 1.7, 2.0];
const int readerDefaultLineSpacing = 2;

/// Extra space between letters, as a share of the text size.
const List<double> readerLetterSpacings = <double>[0, 0.03, 0.06, 0.1];
const int readerDefaultLetterSpacing = 0;

/// Space left and right of the text, in logical pixels.
const List<double> readerMargins = <double>[12, 20, 32, 48, 64];
const int readerDefaultMargin = 1;

/// Whether the viewer is in reader mode and how the reader looks. Read from
/// disk, so decoding is tolerant: a bad field is replaced by its default.
/// Every step is an index into its table above, so no value can be outside
/// what the reader has been made to look right at. Text is always left-aligned.
class ReaderSettings {
  const ReaderSettings({
    this.enabled = false,
    this.theme = ReaderTheme.black,
    this.size = readerDefaultSize,
    this.lineSpacing = readerDefaultLineSpacing,
    this.letterSpacing = readerDefaultLetterSpacing,
    this.margin = readerDefaultMargin,
    this.bold = false,
    this.font = ReaderFont.system,
  });

  /// Pages show as reader text instead of the teletext grid.
  final bool enabled;
  final ReaderTheme theme;

  /// An index into [readerTextSizes].
  final int size;

  /// An index into [readerLineHeights].
  final int lineSpacing;

  /// An index into [readerLetterSpacings].
  final int letterSpacing;

  /// An index into [readerMargins].
  final int margin;

  /// Thicker strokes, which many people find easier to read.
  final bool bold;

  /// The typeface of the text.
  final ReaderFont font;

  double get fontSize => readerTextSizes[size];
  double get lineHeight => readerLineHeights[lineSpacing];
  double get letterSpacingEm => readerLetterSpacings[letterSpacing];
  double get marginWidth => readerMargins[margin];

  ReaderSettings copyWith({
    bool? enabled,
    ReaderTheme? theme,
    int? size,
    int? lineSpacing,
    int? letterSpacing,
    int? margin,
    bool? bold,
    ReaderFont? font,
  }) => ReaderSettings(
    enabled: enabled ?? this.enabled,
    theme: theme ?? this.theme,
    size: size ?? this.size,
    lineSpacing: lineSpacing ?? this.lineSpacing,
    letterSpacing: letterSpacing ?? this.letterSpacing,
    margin: margin ?? this.margin,
    bold: bold ?? this.bold,
    font: font ?? this.font,
  );

  /// The spacing, margins and weight back to their defaults; the mode, the
  /// colours, the text size and the typeface (a choice of the reader's, not
  /// of layout) are left as they are.
  ReaderSettings resetLayout() =>
      ReaderSettings(enabled: enabled, theme: theme, size: size, font: font);

  static int _step(Object? value, int length, int fallback) =>
      value is int && value >= 0 && value < length ? value : fallback;

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
    final Object? bold = json['bold'];
    return ReaderSettings(
      enabled: enabled is bool && enabled,
      theme: ReaderTheme.values.asNameMap()[theme] ?? ReaderTheme.black,
      size: _step(json['size'], readerTextSizes.length, readerDefaultSize),
      lineSpacing: _step(
        json['lineSpacing'],
        readerLineHeights.length,
        readerDefaultLineSpacing,
      ),
      letterSpacing: _step(
        json['letterSpacing'],
        readerLetterSpacings.length,
        readerDefaultLetterSpacing,
      ),
      margin: _step(json['margin'], readerMargins.length, readerDefaultMargin),
      bold: bold is bool && bold,
      font: ReaderFont.values.asNameMap()[json['font']] ?? ReaderFont.system,
    );
  }

  String encode() => jsonEncode(<String, Object?>{
    'enabled': enabled,
    'theme': theme.name,
    'size': size,
    'lineSpacing': lineSpacing,
    'letterSpacing': letterSpacing,
    'margin': margin,
    'bold': bold,
    'font': font.name,
  });

  @override
  bool operator ==(Object other) =>
      other is ReaderSettings &&
      other.enabled == enabled &&
      other.theme == theme &&
      other.size == size &&
      other.lineSpacing == lineSpacing &&
      other.letterSpacing == letterSpacing &&
      other.margin == margin &&
      other.bold == bold &&
      other.font == font;

  @override
  int get hashCode => Object.hash(
    enabled,
    theme,
    size,
    lineSpacing,
    letterSpacing,
    margin,
    bold,
    font,
  );
}
