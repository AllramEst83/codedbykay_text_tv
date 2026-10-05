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
