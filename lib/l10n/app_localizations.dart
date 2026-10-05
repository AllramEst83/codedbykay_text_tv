import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_sv.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('sv'),
  ];

  /// The app's name in the top bar, in capitals.
  ///
  /// In en, this message translates to:
  /// **'TEXT TV'**
  String get title;

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'LOADING...'**
  String get loading;

  /// No description provided for @tryAgain.
  ///
  /// In en, this message translates to:
  /// **'TRY AGAIN'**
  String get tryAgain;

  /// Spoken label of the refresh icon button.
  ///
  /// In en, this message translates to:
  /// **'Refresh the page'**
  String get refreshPage;

  /// Before 'n/m' on the bar that steps through the parts (sub-pages) of a page.
  ///
  /// In en, this message translates to:
  /// **'PART'**
  String get part;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'SETTINGS'**
  String get settingsTitle;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @back.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

  /// No description provided for @sectionFavourites.
  ///
  /// In en, this message translates to:
  /// **'FAVOURITES'**
  String get sectionFavourites;

  /// No description provided for @sectionLanguage.
  ///
  /// In en, this message translates to:
  /// **'LANGUAGE'**
  String get sectionLanguage;

  /// No description provided for @langSystem.
  ///
  /// In en, this message translates to:
  /// **'SYSTEM'**
  String get langSystem;

  /// No description provided for @langSwedish.
  ///
  /// In en, this message translates to:
  /// **'SVENSKA'**
  String get langSwedish;

  /// No description provided for @langEnglish.
  ///
  /// In en, this message translates to:
  /// **'ENGLISH'**
  String get langEnglish;

  /// No description provided for @languageNote.
  ///
  /// In en, this message translates to:
  /// **'SYSTEM follows the phone\'s language. If the phone uses a language this app does not have, English is used.'**
  String get languageNote;

  /// No description provided for @sectionPageFont.
  ///
  /// In en, this message translates to:
  /// **'TELETEXT FONT'**
  String get sectionPageFont;

  /// No description provided for @pageFontPixel.
  ///
  /// In en, this message translates to:
  /// **'PRESS START 2P'**
  String get pageFontPixel;

  /// No description provided for @pageFontBedstead.
  ///
  /// In en, this message translates to:
  /// **'BEDSTEAD'**
  String get pageFontBedstead;

  /// No description provided for @pageFontNote.
  ///
  /// In en, this message translates to:
  /// **'Bedstead is drawn after the teletext of the 1980s. It applies to the teletext page, not to reader mode.'**
  String get pageFontNote;

  /// No description provided for @pageFontPreview.
  ///
  /// In en, this message translates to:
  /// **'Preview of the teletext font'**
  String get pageFontPreview;

  /// No description provided for @sectionBackground.
  ///
  /// In en, this message translates to:
  /// **'WIDGET AND ALERTS'**
  String get sectionBackground;

  /// No description provided for @widgetPage.
  ///
  /// In en, this message translates to:
  /// **'WIDGET PAGE'**
  String get widgetPage;

  /// No description provided for @backgroundEvery.
  ///
  /// In en, this message translates to:
  /// **'CHECK EVERY'**
  String get backgroundEvery;

  /// No description provided for @every30Min.
  ///
  /// In en, this message translates to:
  /// **'30 MIN'**
  String get every30Min;

  /// No description provided for @every1Hour.
  ///
  /// In en, this message translates to:
  /// **'1 H'**
  String get every1Hour;

  /// No description provided for @every3Hours.
  ///
  /// In en, this message translates to:
  /// **'3 H'**
  String get every3Hours;

  /// No description provided for @pickerTitle.
  ///
  /// In en, this message translates to:
  /// **'CHOOSE A PAGE'**
  String get pickerTitle;

  /// No description provided for @pickerHint.
  ///
  /// In en, this message translates to:
  /// **'STAR A PAGE TO FIND IT HERE.'**
  String get pickerHint;

  /// No description provided for @backgroundNote.
  ///
  /// In en, this message translates to:
  /// **'The widget is refreshed in the background at this interval, and only while it is on a home screen. Each check asks texttv.nu for one page.'**
  String get backgroundNote;

  /// No description provided for @alertsOn.
  ///
  /// In en, this message translates to:
  /// **'BREAKING-NEWS ALERTS'**
  String get alertsOn;

  /// No description provided for @alertPage.
  ///
  /// In en, this message translates to:
  /// **'ALERT PAGE'**
  String get alertPage;

  /// No description provided for @alertsDenied.
  ///
  /// In en, this message translates to:
  /// **'NOTIFICATIONS ARE OFF FOR THIS APP. TURN THEM ON IN THE PHONE\'S SETTINGS.'**
  String get alertsDenied;

  /// No description provided for @alertsNote.
  ///
  /// In en, this message translates to:
  /// **'When the top headline of the alert page changes, a notification shows it. The page is checked at the interval above, so an alert can come up to that long after the news.'**
  String get alertsNote;

  /// No description provided for @sectionControls.
  ///
  /// In en, this message translates to:
  /// **'CONTROLS'**
  String get sectionControls;

  /// No description provided for @sectionRefresh.
  ///
  /// In en, this message translates to:
  /// **'REFRESH'**
  String get sectionRefresh;

  /// No description provided for @sectionAbout.
  ///
  /// In en, this message translates to:
  /// **'ABOUT'**
  String get sectionAbout;

  /// No description provided for @aboutCredit.
  ///
  /// In en, this message translates to:
  /// **'The pages are SVT Text, which belongs to Sveriges Television. They reach this app through texttv.nu, which is run by someone other than this app\'s maker. This app is not made, approved or supported by SVT or texttv.nu.'**
  String get aboutCredit;

  /// No description provided for @aboutPrivacy.
  ///
  /// In en, this message translates to:
  /// **'No account, no ads, no tracking. The only thing this app sends is the number of the page you ask for, to texttv.nu. The pages you have read, your favourites and your settings stay on this phone.'**
  String get aboutPrivacy;

  /// No description provided for @sectionCrt.
  ///
  /// In en, this message translates to:
  /// **'CRT SCREEN'**
  String get sectionCrt;

  /// No description provided for @recentPages.
  ///
  /// In en, this message translates to:
  /// **'Recent pages'**
  String get recentPages;

  /// No description provided for @recentsTitle.
  ///
  /// In en, this message translates to:
  /// **'RECENT PAGES'**
  String get recentsTitle;

  /// No description provided for @recentsEmpty.
  ///
  /// In en, this message translates to:
  /// **'NO OTHER PAGES READ YET.'**
  String get recentsEmpty;

  /// No description provided for @clearRecents.
  ///
  /// In en, this message translates to:
  /// **'CLEAR LIST'**
  String get clearRecents;

  /// No description provided for @resetFavourites.
  ///
  /// In en, this message translates to:
  /// **'RESET FAVOURITES'**
  String get resetFavourites;

  /// No description provided for @favouritesHint.
  ///
  /// In en, this message translates to:
  /// **'NO FAVOURITES. TAP THE STAR.'**
  String get favouritesHint;

  /// No description provided for @addFavourite.
  ///
  /// In en, this message translates to:
  /// **'Add to favourites'**
  String get addFavourite;

  /// No description provided for @removeFavourite.
  ///
  /// In en, this message translates to:
  /// **'Remove from favourites'**
  String get removeFavourite;

  /// No description provided for @favouritesCount.
  ///
  /// In en, this message translates to:
  /// **'{count} OF {max} SAVED'**
  String favouritesCount(int count, int max);

  /// No description provided for @quickEntry.
  ///
  /// In en, this message translates to:
  /// **'ALWAYS-ON NUMBER PAD AND COLOUR KEYS'**
  String get quickEntry;

  /// No description provided for @autoRefresh.
  ///
  /// In en, this message translates to:
  /// **'AUTO REFRESH'**
  String get autoRefresh;

  /// No description provided for @prefetch.
  ///
  /// In en, this message translates to:
  /// **'READ AHEAD: NEXT AND LINKED PAGES'**
  String get prefetch;

  /// No description provided for @autoRefreshOff.
  ///
  /// In en, this message translates to:
  /// **'OFF'**
  String get autoRefreshOff;

  /// No description provided for @autoRefreshSeconds.
  ///
  /// In en, this message translates to:
  /// **'{seconds} S'**
  String autoRefreshSeconds(int seconds);

  /// No description provided for @autoRefreshMinutes.
  ///
  /// In en, this message translates to:
  /// **'{minutes} MIN'**
  String autoRefreshMinutes(int minutes);

  /// Under the page: when it was last read from the site.
  ///
  /// In en, this message translates to:
  /// **'UPDATED {when}'**
  String updated(String when);

  /// Under the page: it is a saved copy, saved at this time.
  ///
  /// In en, this message translates to:
  /// **'OFFLINE. SAVED {when}'**
  String offlineSaved(String when);

  /// No description provided for @crtEffect.
  ///
  /// In en, this message translates to:
  /// **'CRT EFFECT'**
  String get crtEffect;

  /// No description provided for @crtCurve.
  ///
  /// In en, this message translates to:
  /// **'SCREEN CURVE'**
  String get crtCurve;

  /// No description provided for @crtScanDepth.
  ///
  /// In en, this message translates to:
  /// **'SCANLINE DARKNESS'**
  String get crtScanDepth;

  /// No description provided for @crtScanPeriod.
  ///
  /// In en, this message translates to:
  /// **'SCANLINE SPACING'**
  String get crtScanPeriod;

  /// No description provided for @crtPreview.
  ///
  /// In en, this message translates to:
  /// **'Preview of the CRT look'**
  String get crtPreview;

  /// No description provided for @reset.
  ///
  /// In en, this message translates to:
  /// **'RESET'**
  String get reset;

  /// No description provided for @readerOn.
  ///
  /// In en, this message translates to:
  /// **'Reader mode'**
  String get readerOn;

  /// No description provided for @readerOff.
  ///
  /// In en, this message translates to:
  /// **'Show the teletext page'**
  String get readerOff;

  /// No description provided for @readerOptions.
  ///
  /// In en, this message translates to:
  /// **'Reader options'**
  String get readerOptions;

  /// No description provided for @readerOptionsTitle.
  ///
  /// In en, this message translates to:
  /// **'READER OPTIONS'**
  String get readerOptionsTitle;

  /// No description provided for @readerFont.
  ///
  /// In en, this message translates to:
  /// **'FONT'**
  String get readerFont;

  /// No description provided for @fontSystem.
  ///
  /// In en, this message translates to:
  /// **'SYSTEM'**
  String get fontSystem;

  /// No description provided for @fontAtkinson.
  ///
  /// In en, this message translates to:
  /// **'ATKINSON'**
  String get fontAtkinson;

  /// No description provided for @fontDyslexic.
  ///
  /// In en, this message translates to:
  /// **'OPENDYSLEXIC'**
  String get fontDyslexic;

  /// No description provided for @lineSpacing.
  ///
  /// In en, this message translates to:
  /// **'LINE SPACING'**
  String get lineSpacing;

  /// No description provided for @letterSpacing.
  ///
  /// In en, this message translates to:
  /// **'LETTER SPACING'**
  String get letterSpacing;

  /// No description provided for @margins.
  ///
  /// In en, this message translates to:
  /// **'MARGINS'**
  String get margins;

  /// No description provided for @boldText.
  ///
  /// In en, this message translates to:
  /// **'BOLD TEXT'**
  String get boldText;

  /// No description provided for @smallerText.
  ///
  /// In en, this message translates to:
  /// **'Smaller text'**
  String get smallerText;

  /// No description provided for @largerText.
  ///
  /// In en, this message translates to:
  /// **'Larger text'**
  String get largerText;

  /// No description provided for @readerLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading…'**
  String get readerLoading;

  /// No description provided for @readerTryAgain.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get readerTryAgain;

  /// No description provided for @readerNotBroadcast.
  ///
  /// In en, this message translates to:
  /// **'Page {page} is not in broadcast.'**
  String readerNotBroadcast(int page);

  /// No description provided for @pageLabel.
  ///
  /// In en, this message translates to:
  /// **'Page {page}'**
  String pageLabel(int page);

  /// Spoken label of the page on show when it has several parts.
  ///
  /// In en, this message translates to:
  /// **'Page {page}, part {part} of {parts}'**
  String pageAndPart(int page, int part, int parts);

  /// No description provided for @pageNotBroadcast.
  ///
  /// In en, this message translates to:
  /// **'PAGE {page} IS NOT IN BROADCAST.'**
  String pageNotBroadcast(int page);

  /// No description provided for @themeBlack.
  ///
  /// In en, this message translates to:
  /// **'Black'**
  String get themeBlack;

  /// No description provided for @themeGrey.
  ///
  /// In en, this message translates to:
  /// **'Grey'**
  String get themeGrey;

  /// No description provided for @themeBeige.
  ///
  /// In en, this message translates to:
  /// **'Beige'**
  String get themeBeige;

  /// No description provided for @themePaper.
  ///
  /// In en, this message translates to:
  /// **'Paper'**
  String get themePaper;

  /// No description provided for @themeContrast.
  ///
  /// In en, this message translates to:
  /// **'High contrast'**
  String get themeContrast;

  /// No description provided for @failureOffline.
  ///
  /// In en, this message translates to:
  /// **'No connection. Check your network.'**
  String get failureOffline;

  /// No description provided for @failureTimeout.
  ///
  /// In en, this message translates to:
  /// **'texttv.nu is not answering.'**
  String get failureTimeout;

  /// No description provided for @failureServer.
  ///
  /// In en, this message translates to:
  /// **'texttv.nu has a problem. Try again soon.'**
  String get failureServer;

  /// No description provided for @failureChanged.
  ///
  /// In en, this message translates to:
  /// **'texttv.nu sent something this app cannot read. The site may have changed.'**
  String get failureChanged;

  /// No description provided for @failureOther.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong.'**
  String get failureOther;

  /// No description provided for @search.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get search;

  /// No description provided for @searchTitle.
  ///
  /// In en, this message translates to:
  /// **'SEARCH'**
  String get searchTitle;

  /// No description provided for @searchHint.
  ///
  /// In en, this message translates to:
  /// **'WORD OR PAGE NUMBER'**
  String get searchHint;

  /// No description provided for @searchScope.
  ///
  /// In en, this message translates to:
  /// **'FINDS WORDS ON PAGES YOU HAVE READ.'**
  String get searchScope;

  /// No description provided for @searchNothing.
  ///
  /// In en, this message translates to:
  /// **'NO READ PAGE HAS THAT.'**
  String get searchNothing;

  /// No description provided for @searchGo.
  ///
  /// In en, this message translates to:
  /// **'GO TO PAGE {page}'**
  String searchGo(int page);

  /// No description provided for @share.
  ///
  /// In en, this message translates to:
  /// **'Copy or share this page'**
  String get share;

  /// No description provided for @shareTitle.
  ///
  /// In en, this message translates to:
  /// **'COPY OR SHARE'**
  String get shareTitle;

  /// No description provided for @copyText.
  ///
  /// In en, this message translates to:
  /// **'COPY TEXT'**
  String get copyText;

  /// No description provided for @shareText.
  ///
  /// In en, this message translates to:
  /// **'SHARE TEXT'**
  String get shareText;

  /// No description provided for @shareLink.
  ///
  /// In en, this message translates to:
  /// **'SHARE LINK'**
  String get shareLink;

  /// No description provided for @shareImage.
  ///
  /// In en, this message translates to:
  /// **'SHARE IMAGE'**
  String get shareImage;

  /// No description provided for @copied.
  ///
  /// In en, this message translates to:
  /// **'COPIED'**
  String get copied;

  /// Short names of the pages the fresh install has as favourites (100, 101, 104, 300, 400, 700), shown on their chips.
  ///
  /// In en, this message translates to:
  /// **'NEWS'**
  String get sectionNews;

  /// No description provided for @sectionDomestic.
  ///
  /// In en, this message translates to:
  /// **'DOMESTIC'**
  String get sectionDomestic;

  /// No description provided for @sectionWorld.
  ///
  /// In en, this message translates to:
  /// **'WORLD'**
  String get sectionWorld;

  /// No description provided for @sectionSport.
  ///
  /// In en, this message translates to:
  /// **'SPORT'**
  String get sectionSport;

  /// No description provided for @sectionWeather.
  ///
  /// In en, this message translates to:
  /// **'WEATHER'**
  String get sectionWeather;

  /// No description provided for @sectionIndex.
  ///
  /// In en, this message translates to:
  /// **'INDEX'**
  String get sectionIndex;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'sv'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'sv':
      return AppLocalizationsSv();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
