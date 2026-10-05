import 'package:codedbykay_text_tv/model/page_font_settings.dart';
import 'package:codedbykay_text_tv/model/reader_settings.dart';
import 'package:flutter/material.dart';

/// The viewer's chrome: black, flat, in the teletext colours. The page itself
/// is painted with its own fixed palette (see `tvColorOf`).
abstract final class TvColors {
  static const Color black = Color(0xFF000000);
  static const Color white = Color(0xFFFFFFFF);
  static const Color dim = Color(0xFF808080);
  static const Color border = Color(0xFF555555);
  static const Color highlight = Color(0xFFFFFF00);
}

abstract final class TvMetrics {
  static const double gutter = 8;
  static const double margin = 12;
  static const double border = 2;
}

/// Press Start 2P, bundled so the app works offline.
const String kPixelFontFamily = 'PressStart2P';

/// The text style of the teletext page in [font], at a nominal size: the row
/// fits it to the width. Every cell is as wide as an `M`.
TextStyle pageTextStyle(PageFont font) => switch (font) {
  // Press Start 2P is a monospaced pixel face: every cell one square em. The
  // line height gives the rows their natural teletext proportions. The extra
  // line height goes half above and half below the letters; left to the
  // font's own split it all went above, so text sat low in its row and its
  // descenders ran into the row below.
  PageFont.pixel => const TextStyle(
    fontFamily: kPixelFontFamily,
    fontSize: 8,
    height: 1.6,
    leadingDistribution: TextLeadingDistribution.even,
  ),
  // Bedstead cells are 0.6 em wide; a line of 1.2 em makes a row twice as tall
  // as a cell, as on a television.
  PageFont.bedstead => const TextStyle(
    fontFamily: kBedsteadFontFamily,
    fontSize: 8,
    height: 1.2,
    leadingDistribution: TextLeadingDistribution.even,
  ),
};

/// How many cells tall a row of [font] is at least.
double pageRowCells(PageFont font) => switch (font) {
  PageFont.pixel => 1.6,
  PageFont.bedstead => 2.0,
};

/// Whether the letters of [font] are stretched upright to fill a taller row:
/// the pixel face is square and needs it, Bedstead is drawn tall already.
bool pageStretchesGlyphs(PageFont font) => font == PageFont.pixel;

/// Bedstead (CC0), bundled so the app works offline.
const String kBedsteadFontFamily = 'Bedstead';

/// Black and white with the pixel face; the page area sets its own colours.
ThemeData textTvTheme() {
  return ThemeData(
    brightness: Brightness.dark,
    useMaterial3: true,
    fontFamily: kPixelFontFamily,
    scaffoldBackgroundColor: TvColors.black,
    colorScheme: const ColorScheme.dark(
      surface: TvColors.black,
      primary: TvColors.highlight,
      onSurface: TvColors.white,
    ),
  );
}

/// The reader's colours for one scheme.
class ReaderPalette {
  const ReaderPalette({
    required this.background,
    required this.text,
    required this.dim,
    required this.link,
  });

  final Color background;
  final Color text;

  /// Captions and other quiet text.
  final Color dim;

  /// Links, and what looks like one.
  final Color link;
}

ReaderPalette readerPalette(ReaderTheme theme) => switch (theme) {
  ReaderTheme.black => const ReaderPalette(
    background: Color(0xFF000000),
    text: Color(0xFFEFE8D8),
    dim: Color(0xFF9C9686),
    link: Color(0xFFFFD866),
  ),
  ReaderTheme.grey => const ReaderPalette(
    background: Color(0xFF2B2D31),
    text: Color(0xFFDCDEE1),
    dim: Color(0xFF9A9EA4),
    link: Color(0xFF8AB4F8),
  ),
  ReaderTheme.beige => const ReaderPalette(
    background: Color(0xFFF3EAD3),
    text: Color(0xFF3A3226),
    dim: Color(0xFF6B6048),
    link: Color(0xFF1F4E8C),
  ),
  ReaderTheme.paper => const ReaderPalette(
    background: Color(0xFFFFFFFF),
    text: Color(0xFF1A1A1A),
    dim: Color(0xFF666666),
    link: Color(0xFF0B57D0),
  ),
  ReaderTheme.contrast => const ReaderPalette(
    background: Color(0xFF000000),
    text: Color(0xFFFFFF00),
    dim: Color(0xFFE6E680),
    link: Color(0xFFFFFFFF),
  ),
};

/// The reader sets text in the phone's own face (or one of the bundled ones
/// the reader picks), not the pixel font.
const String kReaderFontFamily = 'Roboto';

/// The font family [font] is set in. The bundled families are in pubspec.yaml.
String readerFontFamily(ReaderFont font) => switch (font) {
  ReaderFont.system => kReaderFontFamily,
  ReaderFont.atkinson => 'AtkinsonHyperlegible',
  ReaderFont.dyslexic => 'OpenDyslexic',
};

TextStyle readerTextStyle(
  double size,
  Color colour, {
  FontWeight? weight,
  double height = 1.5,
  double letterSpacing = 0,
  ReaderFont font = ReaderFont.system,
}) => TextStyle(
  fontFamily: readerFontFamily(font),
  fontSize: size,
  height: height,
  color: colour,
  fontWeight: weight,
  letterSpacing: letterSpacing,
);
