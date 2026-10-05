import 'package:codedbykay_text_tv/model/reader_settings.dart';

/// Every string the viewer shows, so the wording stays in one place.
abstract final class Messages {
  static const String title = 'TEXT TV';
  static const String loading = 'LOADING...';
  static const String tryAgain = 'TRY AGAIN';
  static const String refresh = 'REFRESH';
  static const String part = 'PART';
  static const String settingsTitle = 'SETTINGS';
  static const String settings = 'Settings';
  static const String back = 'Back';
  static const String crtEffect = 'CRT EFFECT';
  static const String crtCurve = 'SCREEN CURVE';
  static const String crtScanDepth = 'SCANLINE DARKNESS';
  static const String crtScanPeriod = 'SCANLINE SPACING';
  static const String crtPreview = 'Preview of the CRT look';
  static const String reset = 'RESET';
  static String pixels(double value) => '${value.toStringAsFixed(1)} PX';
  static const String readerOn = 'Reader mode';
  static const String readerOff = 'Show the teletext page';
  static const String smallerText = 'Smaller text';
  static const String largerText = 'Larger text';
  static const String readerLoading = 'Loading…';
  static const String readerTryAgain = 'Try again';
  static String readerNotBroadcast(int number) =>
      'Page $number is not in broadcast.';
  static String pageLabel(int number) => 'Page $number';
  static String themeName(ReaderTheme theme) => switch (theme) {
    ReaderTheme.black => 'Black',
    ReaderTheme.grey => 'Grey',
    ReaderTheme.beige => 'Beige',
    ReaderTheme.paper => 'Paper',
    ReaderTheme.contrast => 'High contrast',
  };
  static String offlineSaved(String when) => 'OFFLINE. SAVED $when';
  static String pageNotBroadcast(int number) =>
      'PAGE $number IS NOT IN BROADCAST.';
}
