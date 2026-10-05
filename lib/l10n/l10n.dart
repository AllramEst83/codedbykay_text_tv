import 'package:codedbykay_text_tv/l10n/app_localizations.dart';
import 'package:codedbykay_text_tv/l10n/app_localizations_en.dart';
import 'package:codedbykay_text_tv/model/language_settings.dart';
import 'package:codedbykay_text_tv/model/network_failure.dart';
import 'package:codedbykay_text_tv/model/page_font_settings.dart';
import 'package:codedbykay_text_tv/model/page_section.dart';
import 'package:codedbykay_text_tv/model/reader_settings.dart';
import 'package:codedbykay_text_tv/model/saved_pages.dart';
import 'package:flutter/widgets.dart';

export 'package:codedbykay_text_tv/l10n/app_localizations.dart';

/// `context.l10n.title`: the app's words in the language of the phone. Without
/// the localization delegates above it (a test that mounts one widget, say) it
/// is English, so no widget ever fails for want of its words.
extension L10nContext on BuildContext {
  AppLocalizations get l10n =>
      Localizations.of<AppLocalizations>(this, AppLocalizations) ??
      AppLocalizationsEn();
}

/// The wordings that are a choice between strings rather than one string, so
/// the choice lives with the model's types and the words with the ARB files.
extension AppWording on AppLocalizations {
  String failure(NetworkFailure failure) => switch (failure) {
    NetworkFailure.offline => failureOffline,
    NetworkFailure.timeout => failureTimeout,
    NetworkFailure.server => failureServer,
    NetworkFailure.changed => failureChanged,
    NetworkFailure.other => failureOther,
  };

  String themeName(ReaderTheme theme) => switch (theme) {
    ReaderTheme.black => themeBlack,
    ReaderTheme.grey => themeGrey,
    ReaderTheme.beige => themeBeige,
    ReaderTheme.paper => themePaper,
    ReaderTheme.contrast => themeContrast,
  };

  /// What a screen reader says for the page on show: `Page 377`, or
  /// `Page 377, part 1 of 2` when it has parts ([part] counts from 0).
  String pageDescription(int page, int part, int parts) =>
      parts > 1 ? pageAndPart(page, part + 1, parts) : pageLabel(page);

  String pageFontName(PageFont font) => switch (font) {
    PageFont.pixel => pageFontPixel,
    PageFont.bedstead => pageFontBedstead,
  };

  String intervalName(int step) => switch (step) {
    0 => every30Min,
    1 => every1Hour,
    _ => every3Hours,
  };

  String languageName(AppLanguage language) => switch (language) {
    AppLanguage.system => langSystem,
    AppLanguage.swedish => langSwedish,
    AppLanguage.english => langEnglish,
  };

  String fontName(ReaderFont font) => switch (font) {
    ReaderFont.system => fontSystem,
    ReaderFont.atkinson => fontAtkinson,
    ReaderFont.dyslexic => fontDyslexic,
  };

  /// `OFF`, `30 S` or `2 MIN`.
  String autoRefreshValue(Duration? every) => every == null
      ? autoRefreshOff
      : every.inSeconds < 120
      ? autoRefreshSeconds(every.inSeconds)
      : autoRefreshMinutes(every.inMinutes);

  String sectionName(PageSection section) => switch (section) {
    PageSection.news => sectionNews,
    PageSection.domestic => sectionDomestic,
    PageSection.world => sectionWorld,
    PageSection.sport => sectionSport,
    PageSection.weather => sectionWeather,
    PageSection.contents => sectionIndex,
  };

  /// What a favourite's chip says: `100 NEWS` for a page the app knows by name
  /// (or one the reader named), else just `377`.
  String chipLabel(Favourite favourite) {
    final String? name = favourite.name;
    if (name != null) return favourite.label;
    final PageSection? section = sectionOf(favourite.page);
    return section == null
        ? '${favourite.page}'
        : '${favourite.page} ${sectionName(section)}';
  }

  /// What a favourite's icon shortcut says: the chip's words, or `Page 377`.
  String shortcutTitle(Favourite favourite) {
    final PageSection? section = sectionOf(favourite.page);
    return favourite.name != null || section != null
        ? chipLabel(favourite)
        : pageLabel(favourite.page);
  }
}
