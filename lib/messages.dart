import 'package:codedbykay_text_tv/model/network_failure.dart';
import 'package:codedbykay_text_tv/model/reader_settings.dart';

/// Every string the viewer shows, so the wording stays in one place.
abstract final class Messages {
  static const String title = 'TEXT TV';
  static const String loading = 'LOADING...';
  static const String tryAgain = 'TRY AGAIN';
  static const String refreshPage = 'Refresh the page';
  static const String part = 'PART';
  static const String settingsTitle = 'SETTINGS';
  static const String sectionFavourites = 'FAVOURITES';
  static const String recentPages = 'Recent pages';
  static const String recentsTitle = 'RECENT PAGES';
  static const String recentsEmpty = 'NO OTHER PAGES READ YET.';
  static const String clearRecents = 'CLEAR LIST';
  static const String resetFavourites = 'RESET FAVOURITES';
  static const String favouritesHint = 'NO FAVOURITES. TAP THE STAR.';
  static const String addFavourite = 'Add to favourites';
  static const String removeFavourite = 'Remove from favourites';
  static String favouritesCount(int n, int max) => '$n OF $max SAVED';
  static const String search = 'Search';
  static const String searchTitle = 'SEARCH';
  static const String searchHint = 'WORD OR PAGE NUMBER';
  static const String searchScope = 'FINDS WORDS ON PAGES YOU HAVE READ.';
  static const String searchNothing = 'NO READ PAGE HAS THAT.';
  static String searchGo(int page) => 'GO TO PAGE $page';
  static const String share = 'Copy or share this page';
  static const String shareTitle = 'COPY OR SHARE';
  static const String copyText = 'COPY TEXT';
  static const String shareText = 'SHARE TEXT';
  static const String shareLink = 'SHARE LINK';
  static const String shareImage = 'SHARE IMAGE';
  static const String copied = 'COPIED';
  static const String sectionControls = 'CONTROLS';
  static const String quickEntry = 'ALWAYS-ON NUMBER PAD AND COLOUR KEYS';
  static const String sectionRefresh = 'REFRESH';
  static const String sectionCrt = 'CRT SCREEN';
  static const String autoRefresh = 'AUTO REFRESH';
  static const String prefetch = 'READ AHEAD: NEXT AND LINKED PAGES';
  static String autoRefreshValue(Duration? every) => every == null
      ? 'OFF'
      : every.inSeconds < 120
      ? '${every.inSeconds} S'
      : '${every.inMinutes} MIN';
  static String updated(String when) => 'UPDATED $when';
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
  static const String readerOptions = 'Reader options';
  static const String readerOptionsTitle = 'READER OPTIONS';
  static const String lineSpacing = 'LINE SPACING';
  static const String letterSpacing = 'LETTER SPACING';
  static const String margins = 'MARGINS';
  static const String boldText = 'BOLD TEXT';
  static String times(double value) => 'x${value.toStringAsFixed(2)}';
  static String percent(double fraction) => '${(fraction * 100).round()}%';
  static String logicalPixels(double value) => '${value.round()} PX';
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
  static String failure(NetworkFailure failure) => switch (failure) {
    NetworkFailure.offline => 'No connection. Check your network.',
    NetworkFailure.timeout => 'texttv.nu is not answering.',
    NetworkFailure.server => 'texttv.nu has a problem. Try again soon.',
    NetworkFailure.changed =>
      'texttv.nu sent something this app cannot read. The site may have '
          'changed.',
    NetworkFailure.other => 'Something went wrong.',
  };
}
