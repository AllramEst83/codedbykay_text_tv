// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get title => 'TEXT TV';

  @override
  String get loading => 'LOADING...';

  @override
  String get tryAgain => 'TRY AGAIN';

  @override
  String get refreshPage => 'Refresh the page';

  @override
  String get part => 'PART';

  @override
  String get settingsTitle => 'SETTINGS';

  @override
  String get settings => 'Settings';

  @override
  String get back => 'Back';

  @override
  String get sectionFavourites => 'FAVOURITES';

  @override
  String get sectionLanguage => 'LANGUAGE';

  @override
  String get langSystem => 'SYSTEM';

  @override
  String get langSwedish => 'SVENSKA';

  @override
  String get langEnglish => 'ENGLISH';

  @override
  String get languageNote =>
      'SYSTEM follows the phone\'s language. If the phone uses a language this app does not have, English is used.';

  @override
  String get sectionPageFont => 'TELETEXT FONT';

  @override
  String get pageFontPixel => 'PRESS START 2P';

  @override
  String get pageFontBedstead => 'BEDSTEAD';

  @override
  String get pageFontNote =>
      'Bedstead is drawn after the teletext of the 1980s. It applies to the teletext page, not to reader mode.';

  @override
  String get pageFontPreview => 'Preview of the teletext font';

  @override
  String get sectionBackground => 'WIDGET AND ALERTS';

  @override
  String get widgetPage => 'WIDGET PAGE';

  @override
  String get backgroundEvery => 'CHECK EVERY';

  @override
  String get every30Min => '30 MIN';

  @override
  String get every1Hour => '1 H';

  @override
  String get every3Hours => '3 H';

  @override
  String get pickerTitle => 'CHOOSE A PAGE';

  @override
  String get pickerHint => 'STAR A PAGE TO FIND IT HERE.';

  @override
  String get backgroundNote =>
      'The widget is refreshed in the background at this interval, and only while it is on a home screen. Each check asks texttv.nu for one page.';

  @override
  String get alertsOn => 'BREAKING-NEWS ALERTS';

  @override
  String get alertPage => 'ALERT PAGE';

  @override
  String get alertsDenied =>
      'NOTIFICATIONS ARE OFF FOR THIS APP. TURN THEM ON IN THE PHONE\'S SETTINGS.';

  @override
  String get alertsNote =>
      'When the top headline of the alert page changes, a notification shows it. The page is checked at the interval above, so an alert can come up to that long after the news.';

  @override
  String get sectionControls => 'CONTROLS';

  @override
  String get sectionRefresh => 'REFRESH';

  @override
  String get sectionAbout => 'ABOUT';

  @override
  String get aboutCredit =>
      'The pages are SVT Text, which belongs to Sveriges Television. They reach this app through texttv.nu, which is run by someone other than this app\'s maker. This app is not made, approved or supported by SVT or texttv.nu.';

  @override
  String get aboutPrivacy =>
      'No account, no ads, no tracking. The only thing this app sends is the number of the page you ask for, to texttv.nu. The pages you have read, your favourites and your settings stay on this phone.';

  @override
  String get sectionCrt => 'CRT SCREEN';

  @override
  String get recentPages => 'Recent pages';

  @override
  String get recentsTitle => 'RECENT PAGES';

  @override
  String get recentsEmpty => 'NO OTHER PAGES READ YET.';

  @override
  String get clearRecents => 'CLEAR LIST';

  @override
  String get resetFavourites => 'RESET FAVOURITES';

  @override
  String get favouritesHint => 'NO FAVOURITES. TAP THE STAR.';

  @override
  String get addFavourite => 'Add to favourites';

  @override
  String get removeFavourite => 'Remove from favourites';

  @override
  String favouritesCount(int count, int max) {
    return '$count OF $max SAVED';
  }

  @override
  String get quickEntry => 'ALWAYS-ON NUMBER PAD AND COLOUR KEYS';

  @override
  String get autoRefresh => 'AUTO REFRESH';

  @override
  String get prefetch => 'READ AHEAD: NEXT AND LINKED PAGES';

  @override
  String get autoRefreshOff => 'OFF';

  @override
  String autoRefreshSeconds(int seconds) {
    return '$seconds S';
  }

  @override
  String autoRefreshMinutes(int minutes) {
    return '$minutes MIN';
  }

  @override
  String updated(String when) {
    return 'UPDATED $when';
  }

  @override
  String offlineSaved(String when) {
    return 'OFFLINE. SAVED $when';
  }

  @override
  String get crtEffect => 'CRT EFFECT';

  @override
  String get crtCurve => 'SCREEN CURVE';

  @override
  String get crtScanDepth => 'SCANLINE DARKNESS';

  @override
  String get crtScanPeriod => 'SCANLINE SPACING';

  @override
  String get crtPreview => 'Preview of the CRT look';

  @override
  String get reset => 'RESET';

  @override
  String get readerOn => 'Reader mode';

  @override
  String get readerOff => 'Show the teletext page';

  @override
  String get readerOptions => 'Reader options';

  @override
  String get readerOptionsTitle => 'READER OPTIONS';

  @override
  String get readerFont => 'FONT';

  @override
  String get fontSystem => 'SYSTEM';

  @override
  String get fontAtkinson => 'ATKINSON';

  @override
  String get fontDyslexic => 'OPENDYSLEXIC';

  @override
  String get lineSpacing => 'LINE SPACING';

  @override
  String get letterSpacing => 'LETTER SPACING';

  @override
  String get margins => 'MARGINS';

  @override
  String get boldText => 'BOLD TEXT';

  @override
  String get smallerText => 'Smaller text';

  @override
  String get largerText => 'Larger text';

  @override
  String get readerLoading => 'Loading…';

  @override
  String get readerTryAgain => 'Try again';

  @override
  String readerNotBroadcast(int page) {
    return 'Page $page is not in broadcast.';
  }

  @override
  String pageLabel(int page) {
    return 'Page $page';
  }

  @override
  String pageAndPart(int page, int part, int parts) {
    return 'Page $page, part $part of $parts';
  }

  @override
  String pageNotBroadcast(int page) {
    return 'PAGE $page IS NOT IN BROADCAST.';
  }

  @override
  String get themeBlack => 'Black';

  @override
  String get themeGrey => 'Grey';

  @override
  String get themeBeige => 'Beige';

  @override
  String get themePaper => 'Paper';

  @override
  String get themeContrast => 'High contrast';

  @override
  String get failureOffline => 'No connection. Check your network.';

  @override
  String get failureTimeout => 'texttv.nu is not answering.';

  @override
  String get failureServer => 'texttv.nu has a problem. Try again soon.';

  @override
  String get failureChanged =>
      'texttv.nu sent something this app cannot read. The site may have changed.';

  @override
  String get failureOther => 'Something went wrong.';

  @override
  String get search => 'Search';

  @override
  String get searchTitle => 'SEARCH';

  @override
  String get searchHint => 'WORD OR PAGE NUMBER';

  @override
  String get searchScope => 'FINDS WORDS ON PAGES YOU HAVE READ.';

  @override
  String get searchNothing => 'NO READ PAGE HAS THAT.';

  @override
  String searchGo(int page) {
    return 'GO TO PAGE $page';
  }

  @override
  String get share => 'Copy or share this page';

  @override
  String get shareTitle => 'COPY OR SHARE';

  @override
  String get copyText => 'COPY TEXT';

  @override
  String get shareText => 'SHARE TEXT';

  @override
  String get shareLink => 'SHARE LINK';

  @override
  String get shareImage => 'SHARE IMAGE';

  @override
  String get copied => 'COPIED';

  @override
  String get sectionNews => 'NEWS';

  @override
  String get sectionDomestic => 'DOMESTIC';

  @override
  String get sectionWorld => 'WORLD';

  @override
  String get sectionSport => 'SPORT';

  @override
  String get sectionWeather => 'WEATHER';

  @override
  String get sectionIndex => 'INDEX';
}
