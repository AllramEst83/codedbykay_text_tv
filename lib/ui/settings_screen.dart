import 'dart:async';

import 'package:codedbykay_text_tv/l10n/l10n.dart';
import 'package:codedbykay_text_tv/model/background_settings.dart';
import 'package:codedbykay_text_tv/model/controls_settings.dart';
import 'package:codedbykay_text_tv/model/crt_settings.dart';
import 'package:codedbykay_text_tv/model/language_settings.dart';
import 'package:codedbykay_text_tv/model/page_font_settings.dart';
import 'package:codedbykay_text_tv/model/refresh_settings.dart';
import 'package:codedbykay_text_tv/model/saved_pages.dart';
import 'package:codedbykay_text_tv/model/styled_text.dart';
import 'package:codedbykay_text_tv/model/text_tv_page.dart';
import 'package:codedbykay_text_tv/services/alert_platform.dart';
import 'package:codedbykay_text_tv/ui/crt_screen.dart';
import 'package:codedbykay_text_tv/ui/formats.dart';
import 'package:codedbykay_text_tv/ui/page_picker_sheet.dart';
import 'package:codedbykay_text_tv/ui/text_tv_controls.dart';
import 'package:codedbykay_text_tv/ui/text_tv_keys.dart';
import 'package:codedbykay_text_tv/ui/theme.dart';
import 'package:codedbykay_text_tv/ui/tv_option_rows.dart';
import 'package:codedbykay_text_tv/ui/tv_row.dart';
import 'package:flutter/material.dart';

/// The settings page: how the page refreshes, and the CRT look of the
/// teletext page. Changes apply
/// at once (the page behind keeps up through [onChanged]) and every slider is
/// held inside the range in `crt_settings.dart`.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({
    super.key,
    required this.background,
    required this.onBackgroundChanged,
    required this.recents,
    this.alerts,
    required this.pageFont,
    required this.onPageFontChanged,
    required this.language,
    required this.onLanguageChanged,
    required this.controls,
    required this.onControlsChanged,
    required this.crt,
    required this.onChanged,
    required this.refresh,
    required this.onRefreshChanged,
    required this.saved,
    required this.onSavedChanged,
  });

  /// What the app does in the background, and the listener for it.
  final BackgroundSettings background;
  final ValueChanged<BackgroundSettings> onBackgroundChanged;

  /// The pages read lately, for the page pickers.
  final List<int> recents;

  /// The phone's notifications, asked for permission when alerts are turned
  /// on. Without it the switch just switches.
  final AlertPlatform? alerts;

  /// The typeface of the teletext page, and the listener for it.
  final PageFontSettings pageFont;
  final ValueChanged<PageFontSettings> onPageFontChanged;

  /// The language of the app, and the listener for it.
  final LanguageSettings language;
  final ValueChanged<LanguageSettings> onLanguageChanged;

  /// The favourite pages, and the listener for them.
  final SavedPages saved;
  final ValueChanged<SavedPages> onSavedChanged;

  /// How the controls under the page work, and the listener for it.
  final ControlsSettings controls;
  final ValueChanged<ControlsSettings> onControlsChanged;

  final CrtSettings crt;
  final ValueChanged<CrtSettings> onChanged;

  /// How often the page refreshes by itself, and the listener for it.
  final RefreshSettings refresh;
  final ValueChanged<RefreshSettings> onRefreshChanged;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late BackgroundSettings _background = widget.background;
  late PageFontSettings _pageFont = widget.pageFont;
  late LanguageSettings _language = widget.language;
  late CrtSettings _crt = widget.crt;
  late ControlsSettings _controls = widget.controls;
  late SavedPages _saved = widget.saved;

  void _setSaved(SavedPages saved) {
    if (saved == _saved) return;
    setState(() => _saved = saved);
    widget.onSavedChanged(saved);
  }

  void _setBackground(BackgroundSettings background) {
    if (background == _background) return;
    setState(() => _background = background);
    widget.onBackgroundChanged(background);
  }

  /// Turns alerts on or off. Turning them on asks the phone for permission to
  /// notify first, and stays off (saying why) when it is refused.
  Future<void> _setAlerts(bool on) async {
    if (on) {
      final AlertPlatform? platform = widget.alerts;
      if (platform != null && !await platform.requestPermission()) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              context.l10n.alertsDenied,
              style: tvText(10, TvColors.white),
            ),
            backgroundColor: TvColors.black,
            shape: const Border.fromBorderSide(
              BorderSide(color: TvColors.border, width: TvMetrics.border),
            ),
            // Straight to where it can be allowed.
            action: SnackBarAction(
              key: textTvOpenSettingsKey,
              label: context.l10n.alertsOpenSettings,
              textColor: TvColors.highlight,
              onPressed: () => unawaited(platform.openSettings()),
            ),
          ),
        );
        return;
      }
    }
    if (mounted) _setBackground(_background.copyWith(alerts: on));
  }

  void _setPageFont(PageFontSettings pageFont) {
    if (pageFont == _pageFont) return;
    setState(() => _pageFont = pageFont);
    widget.onPageFontChanged(pageFont);
  }

  void _setLanguage(LanguageSettings language) {
    if (language == _language) return;
    setState(() => _language = language);
    widget.onLanguageChanged(language);
  }

  void _setControls(ControlsSettings controls) {
    if (controls == _controls) return;
    setState(() => _controls = controls);
    widget.onControlsChanged(controls);
  }

  late RefreshSettings _refresh = widget.refresh;

  void _setRefresh(RefreshSettings refresh) {
    if (refresh == _refresh) return;
    setState(() => _refresh = refresh);
    widget.onRefreshChanged(refresh);
  }

  void _set(CrtSettings crt) {
    if (crt == _crt) return;
    setState(() => _crt = crt);
    widget.onChanged(crt);
  }

  @override
  Widget build(BuildContext context) {
    final bool on = _crt.enabled;
    return Scaffold(
      backgroundColor: TvColors.black,
      body: SafeArea(
        child: Column(
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.all(TvMetrics.gutter),
              child: Row(
                children: <Widget>[
                  TvButton(
                    key: textTvSettingsBackKey,
                    label: '<',
                    semanticLabel: context.l10n.back,
                    onTap: () => Navigator.of(context).maybePop(),
                  ),
                  const SizedBox(width: TvMetrics.margin),
                  Expanded(
                    child: Text(
                      context.l10n.settingsTitle,
                      style: tvText(14, TvColors.white),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                  TvMetrics.margin,
                  TvMetrics.gutter,
                  TvMetrics.margin,
                  TvMetrics.margin * 2,
                ),
                children: <Widget>[
                  _SettingsGroup(
                    id: 'language',
                    title: context.l10n.sectionLanguage,
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          for (final AppLanguage language in AppLanguage.values)
                            Expanded(
                              child: Padding(
                                padding: EdgeInsets.only(
                                  right: language == AppLanguage.values.last
                                      ? 0
                                      : TvMetrics.gutter,
                                ),
                                child: TvChoice(
                                  choiceKey: textTvLanguageKey(language),
                                  label: context.l10n.languageName(language),
                                  selected: _language.language == language,
                                  onTap: () => _setLanguage(
                                    _language.copyWith(language: language),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: TvMetrics.margin),
                      Text(
                        context.l10n.languageNote,
                        key: textTvLanguageNoteKey,
                        style: readerTextStyle(13, TvColors.white),
                      ),
                    ],
                  ),
                  const SizedBox(height: TvMetrics.margin * 2),
                  _SettingsGroup(
                    id: 'controls',
                    title: context.l10n.sectionControls,
                    children: <Widget>[
                      TvSwitchRow(
                        switchKey: textTvQuickEntryKey,
                        label: context.l10n.quickEntry,
                        value: _controls.quickEntry,
                        onChanged: (bool v) =>
                            _setControls(_controls.copyWith(quickEntry: v)),
                      ),
                    ],
                  ),
                  const SizedBox(height: TvMetrics.margin * 2),
                  _SettingsGroup(
                    id: 'favourites',
                    title: context.l10n.sectionFavourites,
                    children: <Widget>[
                      Text(
                        context.l10n.favouritesCount(
                          _saved.favourites.length,
                          SavedPages.maxFavourites,
                        ),
                        style: tvText(10, TvColors.white),
                      ),
                      const SizedBox(height: TvMetrics.margin),
                      TvButton(
                        key: textTvFavouritesResetKey,
                        label: context.l10n.resetFavourites,
                        onTap: _saved.hasDefaultFavourites
                            ? null
                            : () => _setSaved(_saved.resetFavourites()),
                      ),
                    ],
                  ),
                  const SizedBox(height: TvMetrics.margin * 2),
                  _SettingsGroup(
                    id: 'refresh',
                    title: context.l10n.sectionRefresh,
                    children: <Widget>[
                      TvSliderRow(
                        sliderKey: textTvAutoRefreshKey,
                        label: context.l10n.autoRefresh,
                        value: _refresh.auto.toDouble(),
                        max: (autoRefreshIntervals.length - 1).toDouble(),
                        divisions: autoRefreshIntervals.length - 1,
                        text: context.l10n.autoRefreshValue(_refresh.interval),
                        onChanged: (double v) =>
                            _setRefresh(_refresh.copyWith(auto: v.round())),
                      ),
                      const SizedBox(height: TvMetrics.margin),
                      TvSwitchRow(
                        switchKey: textTvPrefetchKey,
                        label: context.l10n.prefetch,
                        value: _refresh.prefetch,
                        onChanged: (bool v) =>
                            _setRefresh(_refresh.copyWith(prefetch: v)),
                      ),
                    ],
                  ),
                  const SizedBox(height: TvMetrics.margin * 2),
                  _SettingsGroup(
                    id: 'background',
                    title: context.l10n.sectionBackground,
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          Expanded(
                            child: Text(
                              context.l10n.widgetPage,
                              style: tvText(12, TvColors.white),
                            ),
                          ),
                          TvButton(
                            key: textTvWidgetPageKey,
                            label: context.l10n.chipLabel(
                              Favourite(_background.widgetPage),
                            ),
                            onTap: () => showPagePicker(
                              context,
                              title: context.l10n.pickerTitle,
                              selected: _background.widgetPage,
                              favourites: _saved.favourites,
                              recents: widget.recents,
                              onPick: (int page) => _setBackground(
                                _background.copyWith(widgetPage: page),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: TvMetrics.margin),
                      TvSwitchRow(
                        switchKey: textTvAlertsKey,
                        label: context.l10n.alertsOn,
                        value: _background.alerts,
                        onChanged: _setAlerts,
                      ),
                      const SizedBox(height: TvMetrics.margin),
                      Row(
                        children: <Widget>[
                          Expanded(
                            child: Text(
                              context.l10n.alertPage,
                              style: tvText(
                                12,
                                _background.alerts
                                    ? TvColors.white
                                    : TvColors.dim,
                              ),
                            ),
                          ),
                          TvButton(
                            key: textTvAlertPageKey,
                            label: context.l10n.chipLabel(
                              Favourite(_background.alertPage),
                            ),
                            onTap: _background.alerts
                                ? () => showPagePicker(
                                    context,
                                    title: context.l10n.pickerTitle,
                                    selected: _background.alertPage,
                                    favourites: _saved.favourites,
                                    recents: widget.recents,
                                    onPick: (int page) => _setBackground(
                                      _background.copyWith(alertPage: page),
                                    ),
                                  )
                                : null,
                          ),
                        ],
                      ),
                      const SizedBox(height: TvMetrics.margin),
                      Text(
                        context.l10n.backgroundEvery,
                        style: tvText(12, TvColors.white),
                      ),
                      const SizedBox(height: TvMetrics.gutter),
                      Row(
                        children: <Widget>[
                          for (
                            int step = 0;
                            step < backgroundIntervals.length;
                            step++
                          )
                            Expanded(
                              child: Padding(
                                padding: EdgeInsets.only(
                                  right: step == backgroundIntervals.length - 1
                                      ? 0
                                      : TvMetrics.gutter,
                                ),
                                child: TvChoice(
                                  choiceKey: textTvIntervalKey(step),
                                  label: context.l10n.intervalName(step),
                                  selected: _background.interval == step,
                                  onTap: () => _setBackground(
                                    _background.copyWith(interval: step),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: TvMetrics.margin),
                      Text(
                        context.l10n.backgroundNote,
                        key: textTvBackgroundNoteKey,
                        style: readerTextStyle(13, TvColors.white),
                      ),
                      const SizedBox(height: TvMetrics.gutter),
                      Text(
                        context.l10n.alertsNote,
                        key: textTvAlertsNoteKey,
                        style: readerTextStyle(13, TvColors.white),
                      ),
                    ],
                  ),
                  const SizedBox(height: TvMetrics.margin * 2),
                  _SettingsGroup(
                    id: 'pagefont',
                    title: context.l10n.sectionPageFont,
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          for (final PageFont font in PageFont.values)
                            Expanded(
                              child: Padding(
                                padding: EdgeInsets.only(
                                  right: font == PageFont.values.last
                                      ? 0
                                      : TvMetrics.gutter,
                                ),
                                child: TvChoice(
                                  choiceKey: textTvPageFontKey(font),
                                  label: context.l10n.pageFontName(font),
                                  selected: _pageFont.font == font,
                                  onTap: () => _setPageFont(
                                    _pageFont.copyWith(font: font),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: TvMetrics.margin),
                      _Preview(
                        settings: CrtSettings.defaults,
                        font: _pageFont.font,
                        previewKey: textTvPageFontPreviewKey,
                        label: context.l10n.pageFontPreview,
                      ),
                      const SizedBox(height: TvMetrics.margin),
                      Text(
                        context.l10n.pageFontNote,
                        key: textTvPageFontNoteKey,
                        style: readerTextStyle(13, TvColors.white),
                      ),
                    ],
                  ),
                  const SizedBox(height: TvMetrics.margin * 2),
                  _SettingsGroup(
                    id: 'crt',
                    title: context.l10n.sectionCrt,
                    children: <Widget>[
                      TvSwitchRow(
                        switchKey: textTvCrtSwitchKey,
                        label: context.l10n.crtEffect,
                        value: on,
                        onChanged: (bool v) => _set(_crt.copyWith(enabled: v)),
                      ),
                      const SizedBox(height: TvMetrics.margin),
                      _Preview(settings: _crt, font: _pageFont.font),
                      const SizedBox(height: TvMetrics.margin),
                      TvSliderRow(
                        sliderKey: textTvCrtCurveKey,
                        label: context.l10n.crtCurve,
                        value: _crt.curve,
                        max: crtCurveMax,
                        text: _percent(_crt.curve, 0, crtCurveMax),
                        onChanged: on
                            ? (double v) => _set(_crt.copyWith(curve: v))
                            : null,
                      ),
                      TvSliderRow(
                        sliderKey: textTvCrtDepthKey,
                        label: context.l10n.crtScanDepth,
                        value: _crt.scanDepth,
                        max: crtScanDepthMax,
                        text: _percent(_crt.scanDepth, 0, crtScanDepthMax),
                        onChanged: on
                            ? (double v) => _set(_crt.copyWith(scanDepth: v))
                            : null,
                      ),
                      TvSliderRow(
                        sliderKey: textTvCrtPeriodKey,
                        label: context.l10n.crtScanPeriod,
                        value: _crt.scanPeriod,
                        min: crtScanPeriodMin,
                        max: crtScanPeriodMax,
                        text: Formats.pixels(_crt.scanPeriod),
                        onChanged: on
                            ? (double v) => _set(_crt.copyWith(scanPeriod: v))
                            : null,
                      ),
                      const SizedBox(height: TvMetrics.margin),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: TvButton(
                          key: textTvCrtResetKey,
                          label: context.l10n.reset,
                          onTap: on ? () => _set(_crt.reset()) : null,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: TvMetrics.margin * 2),
                  _SettingsGroup(
                    id: 'about',
                    title: context.l10n.sectionAbout,
                    children: <Widget>[
                      Text(
                        context.l10n.aboutCredit,
                        key: textTvAboutCreditKey,
                        style: readerTextStyle(13, TvColors.white),
                      ),
                      const SizedBox(height: TvMetrics.margin),
                      Text(
                        context.l10n.aboutPrivacy,
                        key: textTvAboutPrivacyKey,
                        style: readerTextStyle(13, TvColors.white),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// [value] as a share of its range, for people, not for the shader.
  static String _percent(double value, double min, double max) =>
      '${((value - min) / (max - min) * 100).round()}%';
}

/// A few rows of teletext, drawn as the page will be, so a slider can be
/// judged where it is moved.
class _Preview extends StatelessWidget {
  const _Preview({
    required this.settings,
    required this.font,
    this.previewKey = textTvCrtPreviewKey,
    this.label,
  });

  final CrtSettings settings;

  /// The typeface the rows are drawn in.
  final PageFont font;
  final Key previewKey;

  /// What a screen reader says for it; the CRT preview by default.
  final String? label;

  static List<StyledRun> _row(
    String text,
    TvColor fg, {
    TvColor? bg,
  }) => <StyledRun>[
    StyledRun(text.padRight(textTvColumns), fg: fg, bg: bg ?? TvColor.black),
  ];

  @override
  Widget build(BuildContext context) {
    final List<List<StyledRun>> rows = <List<StyledRun>>[
      _row(' TEXT TV  PREVIEW', TvColor.white, bg: TvColor.blue),
      _row(''.padRight(textTvColumns), TvColor.white),
      _row('  Ny rysk attack mot ukrainsk bro', TvColor.yellow),
      _row(''.padRight(textTvColumns), TvColor.white),
      _row('  Ryssland har attackerat ytterligare', TvColor.white),
      _row('  en bro i Kyjiv, den här gången', TvColor.white),
      _row('  samtidigt som Merz är på plats', TvColor.cyan),
      _row(''.padRight(textTvColumns), TvColor.white),
      _row('  Inrikes 101 Utrikes 104', TvColor.green, bg: TvColor.blue),
    ];
    final Widget page = ColoredBox(
      color: TvColors.black,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          for (final List<StyledRun> row in rows)
            TvRow(
              runs: row,
              columns: textTvColumns,
              style: pageTextStyle(font),
              gutterLeft: tvGutterCells ~/ 2,
              stretchGlyphs: pageStretchesGlyphs(font),
            ),
        ],
      ),
    );
    return Semantics(
      label: label ?? context.l10n.crtPreview,
      excludeSemantics: true,
      child: Container(
        key: previewKey,
        decoration: BoxDecoration(
          border: Border.all(color: TvColors.border, width: TvMetrics.border),
        ),
        child: settings.enabled
            ? CrtScreen(settings: settings, child: page)
            : page,
      ),
    );
  }
}

/// One group of settings as a panel of its own: a grey frame, and across its
/// top a bar in the blue of a teletext header with the group's name, so where
/// one group ends and the next begins is plain at a glance.
class _SettingsGroup extends StatelessWidget {
  const _SettingsGroup({
    required this.id,
    required this.title,
    required this.children,
  });

  /// A short name for tests to find the group and its bar by.
  final String id;
  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      explicitChildNodes: true,
      child: Container(
        key: textTvSettingsGroupKey(id),
        decoration: BoxDecoration(
          border: Border.all(color: TvColors.border, width: TvMetrics.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Semantics(
              header: true,
              child: Container(
                key: textTvSettingsHeaderKey(id),
                color: tvColorOf(TvColor.blue),
                padding: const EdgeInsets.symmetric(
                  horizontal: TvMetrics.margin,
                  vertical: TvMetrics.gutter + 2,
                ),
                child: Text(title, style: tvText(10, TvColors.white)),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(TvMetrics.margin),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: children,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
