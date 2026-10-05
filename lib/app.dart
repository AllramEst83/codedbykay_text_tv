import 'package:codedbykay_text_tv/l10n/l10n.dart';
import 'package:codedbykay_text_tv/model/background_settings.dart';
import 'package:codedbykay_text_tv/model/controls_settings.dart';
import 'package:codedbykay_text_tv/model/crt_settings.dart';
import 'package:codedbykay_text_tv/model/language_settings.dart';
import 'package:codedbykay_text_tv/model/page_font_settings.dart';
import 'package:codedbykay_text_tv/model/reader_settings.dart';
import 'package:codedbykay_text_tv/model/refresh_settings.dart';
import 'package:codedbykay_text_tv/model/saved_pages.dart';
import 'package:codedbykay_text_tv/model/text_tv_session.dart';
import 'package:codedbykay_text_tv/services/alert_platform.dart';
import 'package:codedbykay_text_tv/services/open_page_service.dart';
import 'package:codedbykay_text_tv/services/share_service.dart';
import 'package:codedbykay_text_tv/services/shortcut_service.dart';
import 'package:codedbykay_text_tv/services/text_tv_repository.dart';
import 'package:codedbykay_text_tv/ui/text_tv_screen.dart';
import 'package:codedbykay_text_tv/ui/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// The page is always black, so the system bars are too: drawn edge to edge
/// with light icons.
const SystemUiOverlayStyle textTvSystemUi = SystemUiOverlayStyle(
  statusBarColor: Colors.transparent,
  statusBarIconBrightness: Brightness.light,
  systemNavigationBarColor: TvColors.black,
  systemNavigationBarIconBrightness: Brightness.light,
  systemNavigationBarDividerColor: TvColors.black,
  systemNavigationBarContrastEnforced: false,
);

class TextTvApp extends StatefulWidget {
  const TextTvApp({
    super.key,
    required this.repository,
    this.session = const TextTvSession(),
    this.onSessionChanged,
    this.reader = const ReaderSettings(),
    this.onReaderChanged,
    this.crt = CrtSettings.defaults,
    this.onCrtChanged,
    this.refresh = const RefreshSettings(),
    this.onRefreshChanged,
    this.background = BackgroundSettings.defaults,
    this.onBackgroundChanged,
    this.openPages,
    this.alerts,
    this.onResumed,
    this.pageFont = PageFontSettings.defaults,
    this.onPageFontChanged,
    this.language = LanguageSettings.defaults,
    this.onLanguageChanged,
    this.controls = ControlsSettings.defaults,
    this.onControlsChanged,
    this.saved = const SavedPages(),
    this.onSavedChanged,
    this.shortcuts,
    this.share,
  });

  final TextTvRepository repository;

  /// Where the reader left off, or the front page.
  final TextTvSession session;
  final ValueChanged<TextTvSession>? onSessionChanged;

  /// How the reader was set up on the last run.
  final ReaderSettings reader;
  final ValueChanged<ReaderSettings>? onReaderChanged;

  /// The CRT look of the teletext page on the last run.
  final CrtSettings crt;
  final ValueChanged<CrtSettings>? onCrtChanged;

  /// Whether the page refreshes by itself, as of the last run.
  final RefreshSettings refresh;
  final ValueChanged<RefreshSettings>? onRefreshChanged;

  /// What the app does in the background, as of the last run.
  final BackgroundSettings background;
  final ValueChanged<BackgroundSettings>? onBackgroundChanged;

  /// Pages asked for from outside the app (a tap on the widget).
  final OpenPageService? openPages;

  /// The phone's notifications.
  final AlertPlatform? alerts;

  /// Called when the app comes back to the front.
  final VoidCallback? onResumed;

  /// The typeface of the teletext page, as of the last run.
  final PageFontSettings pageFont;
  final ValueChanged<PageFontSettings>? onPageFontChanged;

  /// The language of the app, as of the last run.
  final LanguageSettings language;
  final ValueChanged<LanguageSettings>? onLanguageChanged;

  /// How the controls under the page work, as of the last run.
  final ControlsSettings controls;
  final ValueChanged<ControlsSettings>? onControlsChanged;

  /// The reader's favourite pages, as of the last run.
  final SavedPages saved;
  final ValueChanged<SavedPages>? onSavedChanged;

  /// The app icon's long-press shortcuts.
  final ShortcutService? shortcuts;

  /// The phone's share sheet.
  final SharePlatform? share;

  @override
  State<TextTvApp> createState() => _TextTvAppState();
}

class _TextTvAppState extends State<TextTvApp> {
  late LanguageSettings _language = widget.language;

  void _setLanguage(LanguageSettings language) {
    if (language == _language) return;
    setState(() => _language = language);
    widget.onLanguageChanged?.call(language);
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: textTvSystemUi,
      child: MaterialApp(
        onGenerateTitle: (BuildContext context) => context.l10n.title,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: _language.language.locale,
        // A phone in a language the app lacks (Danish, say) gets English.
        localeResolutionCallback: (
          Locale? device,
          Iterable<Locale> supported,
        ) => resolveLocale(device),
        debugShowCheckedModeBanner: false,
        theme: textTvTheme(),
        home: TextTvScreen(
          repository: widget.repository,
          initial: widget.session,
          onSessionChanged: widget.onSessionChanged,
          reader: widget.reader,
          onReaderChanged: widget.onReaderChanged,
          crt: widget.crt,
          onCrtChanged: widget.onCrtChanged,
          refresh: widget.refresh,
          onRefreshChanged: widget.onRefreshChanged,
          controls: widget.controls,
          onControlsChanged: widget.onControlsChanged,
          saved: widget.saved,
          onSavedChanged: widget.onSavedChanged,
          shortcuts: widget.shortcuts,
          share: widget.share,
          background: widget.background,
          onBackgroundChanged: widget.onBackgroundChanged,
          openPages: widget.openPages,
          alerts: widget.alerts,
          onResumed: widget.onResumed,
          pageFont: widget.pageFont,
          onPageFontChanged: widget.onPageFontChanged,
          language: _language,
          onLanguageChanged: _setLanguage,
        ),
      ),
    );
  }
}
