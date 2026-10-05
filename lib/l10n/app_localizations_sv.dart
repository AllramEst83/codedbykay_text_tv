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
  String get sectionLanguage => 'SPRÅK';

  @override
  String get langSystem => 'SYSTEM';

  @override
  String get langSwedish => 'SVENSKA';

  @override
  String get langEnglish => 'ENGLISH';

  @override
  String get languageNote =>
      'SYSTEM följer telefonens språk. Om telefonen använder ett språk som appen saknar blir det engelska.';

  @override
  String get sectionPageFont => 'TEXT-TV-TYPSNITT';

  @override
  String get pageFontPixel => 'PRESS START 2P';

  @override
  String get pageFontBedstead => 'BEDSTEAD';

  @override
  String get pageFontNote =>
      'Bedstead är ritad efter 80-talets text-tv. Den gäller text-tv-sidan, inte läsläget.';

  @override
  String get pageFontPreview => 'Förhandsvisning av text-TV-typsnittet';

  @override
  String get sectionBackground => 'WIDGET OCH AVISERINGAR';

  @override
  String get widgetPage => 'WIDGETENS SIDA';

  @override
  String get backgroundEvery => 'KOLLA VAR';

  @override
  String get every30Min => '30 MIN';

  @override
  String get every1Hour => '1 TIM';

  @override
  String get every3Hours => '3 TIM';

  @override
  String get pickerTitle => 'VÄLJ EN SIDA';

  @override
  String get pickerHint => 'STJÄRNMARKERA EN SIDA SÅ HITTAR DU DEN HÄR.';

  @override
  String get backgroundNote =>
      'Widgeten uppdateras i bakgrunden med det här mellanrummet, och bara när den ligger på en startskärm. Varje koll hämtar en sida från texttv.nu.';

  @override
  String get alertsOn => 'AVISERING VID SENASTE NYTT';

  @override
  String get alertPage => 'SIDA ATT BEVAKA';

  @override
  String get alertsDenied => 'AVISERINGAR ÄR AVSTÄNGDA FÖR APPEN.';

  @override
  String get alertsOpenSettings => 'ÖPPNA INSTÄLLNINGAR';

  @override
  String get alertsNote =>
      'När den översta rubriken på den bevakade sidan byts ut visas den i en avisering. Sidan kollas med mellanrummet ovan, så en avisering kan komma så lång tid efter nyheten.';

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
  String get breadcrumbsOn => 'BRÖDSMULOR OVAN SIDAN';

  @override
  String get crumbHome => 'HEM';

  @override
  String get crumbsLabel => 'Vägen till den här sidan';

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
  String pageAndPart(int page, int part, int parts) {
    return 'Sida $page, del $part av $parts';
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
