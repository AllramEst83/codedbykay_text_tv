// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Swedish (`sv`).
class AppLocalizationsSv extends AppLocalizations {
  AppLocalizationsSv([String locale = 'sv']) : super(locale);

  @override
  String get title => 'TEXT-TV';

  @override
  String get loading => 'LADDAR...';

  @override
  String get tryAgain => 'FÖRSÖK IGEN';

  @override
  String get refreshPage => 'Uppdatera sidan';

  @override
  String get part => 'DEL';

  @override
  String get settingsTitle => 'INSTÄLLNINGAR';

  @override
  String get settings => 'Inställningar';

  @override
  String get back => 'Tillbaka';

  @override
  String get sectionFavourites => 'FAVORITER';

  @override
  String get sectionControls => 'KNAPPAR';

  @override
  String get sectionRefresh => 'UPPDATERING';

  @override
  String get sectionAbout => 'OM APPEN';

  @override
  String get aboutCredit =>
      'Sidorna är SVT Text, som tillhör Sveriges Television. De hämtas via texttv.nu, som drivs av någon annan än den som har gjort den här appen. Appen är inte gjord, godkänd eller stödd av SVT eller texttv.nu.';

  @override
  String get aboutPrivacy =>
      'Inget konto, inga annonser, ingen spårning. Det enda appen skickar är numret på sidan du vill läsa, till texttv.nu. Sidor du har läst, dina favoriter och dina inställningar sparas bara på den här telefonen.';

  @override
  String get sectionCrt => 'CRT-SKÄRM';

  @override
  String get recentPages => 'Senaste sidor';

  @override
  String get recentsTitle => 'SENASTE SIDOR';

  @override
  String get recentsEmpty => 'INGA ANDRA SIDOR LÄSTA ÄNNU.';

  @override
  String get clearRecents => 'RENSA LISTAN';

  @override
  String get resetFavourites => 'ÅTERSTÄLL FAVORITER';

  @override
  String get favouritesHint => 'INGA FAVORITER. TRYCK PÅ STJÄRNAN.';

  @override
  String get addFavourite => 'Lägg till som favorit';

  @override
  String get removeFavourite => 'Ta bort som favorit';

  @override
  String favouritesCount(int count, int max) {
    return '$count AV $max SPARADE';
  }

  @override
  String get quickEntry => 'SIFFROR OCH FÄRGKNAPPAR ALLTID SYNLIGA';

  @override
  String get autoRefresh => 'AUTOMATISK UPPDATERING';

  @override
  String get prefetch => 'LÄS IN I FÖRVÄG: NÄSTA OCH LÄNKADE SIDOR';

  @override
  String get autoRefreshOff => 'AV';

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
    return 'UPPDATERAD $when';
  }

  @override
  String offlineSaved(String when) {
    return 'OFFLINE. SPARAD $when';
  }

  @override
  String get crtEffect => 'CRT-EFFEKT';

  @override
  String get crtCurve => 'SKÄRMENS KRÖKNING';

  @override
  String get crtScanDepth => 'RADLINJERNAS MÖRKHET';

  @override
  String get crtScanPeriod => 'AVSTÅND MELLAN RADLINJER';

  @override
  String get crtPreview => 'Förhandsvisning av CRT-looken';

  @override
  String get reset => 'ÅTERSTÄLL';

  @override
  String get readerOn => 'Läsläge';

  @override
  String get readerOff => 'Visa text-TV-sidan';

  @override
  String get readerOptions => 'Inställningar för läsläge';

  @override
  String get readerOptionsTitle => 'LÄSLÄGE';

  @override
  String get readerFont => 'TYPSNITT';

  @override
  String get fontSystem => 'SYSTEM';

  @override
  String get fontAtkinson => 'ATKINSON';

  @override
  String get fontDyslexic => 'OPENDYSLEXIC';

  @override
  String get lineSpacing => 'RADAVSTÅND';

  @override
  String get letterSpacing => 'TECKENAVSTÅND';

  @override
  String get margins => 'MARGINALER';

  @override
  String get boldText => 'FET TEXT';

  @override
  String get smallerText => 'Mindre text';

  @override
  String get largerText => 'Större text';

  @override
  String get readerLoading => 'Laddar…';

  @override
  String get readerTryAgain => 'Försök igen';

  @override
  String readerNotBroadcast(int page) {
    return 'Sidan $page sänds inte.';
  }

  @override
  String pageLabel(int page) {
    return 'Sida $page';
  }

  @override
  String pageNotBroadcast(int page) {
    return 'SIDA $page SÄNDS INTE.';
  }

  @override
  String get themeBlack => 'Svart';

  @override
  String get themeGrey => 'Grå';

  @override
  String get themeBeige => 'Beige';

  @override
  String get themePaper => 'Papper';

  @override
  String get themeContrast => 'Hög kontrast';

  @override
  String get failureOffline => 'Ingen anslutning. Kolla nätverket.';

  @override
  String get failureTimeout => 'texttv.nu svarar inte.';

  @override
  String get failureServer =>
      'Det är problem hos texttv.nu. Försök igen om en stund.';

  @override
  String get failureChanged =>
      'texttv.nu skickade något som appen inte kan läsa. Sajten kan ha ändrats.';

  @override
  String get failureOther => 'Något gick fel.';

  @override
  String get search => 'Sök';

  @override
  String get searchTitle => 'SÖK';

  @override
  String get searchHint => 'ORD ELLER SIDNUMMER';

  @override
  String get searchScope => 'SÖKER BARA I SIDOR DU HAR LÄST.';

  @override
  String get searchNothing => 'INGEN LÄST SIDA HAR DET.';

  @override
  String searchGo(int page) {
    return 'GÅ TILL SIDA $page';
  }

  @override
  String get share => 'Kopiera eller dela sidan';

  @override
  String get shareTitle => 'KOPIERA ELLER DELA';

  @override
  String get copyText => 'KOPIERA TEXT';

  @override
  String get shareText => 'DELA TEXT';

  @override
  String get shareLink => 'DELA LÄNK';

  @override
  String get shareImage => 'DELA BILD';

  @override
  String get copied => 'KOPIERAD';

  @override
  String get sectionNews => 'NYHETER';

  @override
  String get sectionDomestic => 'INRIKES';

  @override
  String get sectionWorld => 'UTRIKES';

  @override
  String get sectionSport => 'SPORT';

  @override
  String get sectionWeather => 'VÄDER';

  @override
  String get sectionIndex => 'INNEHÅLL';
}
