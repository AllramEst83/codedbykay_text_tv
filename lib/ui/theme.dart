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

/// The reader sets text in the phone's own face, not the pixel font.
const String kReaderFontFamily = 'Roboto';

TextStyle readerTextStyle(
  double size,
  Color colour, {
  FontWeight? weight,
  double height = 1.5,
}) => TextStyle(
  fontFamily: kReaderFontFamily,
  fontSize: size,
  height: height,
  color: colour,
  fontWeight: weight,
);
