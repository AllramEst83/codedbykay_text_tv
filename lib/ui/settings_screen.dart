import 'package:codedbykay_text_tv/messages.dart';
import 'package:codedbykay_text_tv/model/crt_settings.dart';
import 'package:codedbykay_text_tv/model/styled_text.dart';
import 'package:codedbykay_text_tv/model/text_tv_page.dart';
import 'package:codedbykay_text_tv/ui/crt_screen.dart';
import 'package:codedbykay_text_tv/ui/text_tv_controls.dart';
import 'package:codedbykay_text_tv/ui/text_tv_keys.dart';
import 'package:codedbykay_text_tv/ui/theme.dart';
import 'package:codedbykay_text_tv/ui/tv_row.dart';
import 'package:flutter/material.dart';

/// The settings page: for now the CRT look of the teletext page. Changes apply
/// at once (the page behind keeps up through [onChanged]) and every slider is
/// held inside the range in `crt_settings.dart`.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key, required this.crt, required this.onChanged});

  final CrtSettings crt;
  final ValueChanged<CrtSettings> onChanged;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late CrtSettings _crt = widget.crt;

  void _set(CrtSettings crt) {
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
                    semanticLabel: Messages.back,
                    onTap: () => Navigator.of(context).maybePop(),
                  ),
                  const SizedBox(width: TvMetrics.margin),
                  Expanded(
                    child: Text(
                      Messages.settingsTitle,
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
                  0,
                  TvMetrics.margin,
                  TvMetrics.margin * 2,
                ),
                children: <Widget>[
                  _SwitchRow(
                    label: Messages.crtEffect,
                    value: on,
                    onChanged: (bool v) => _set(_crt.copyWith(enabled: v)),
                  ),
                  const SizedBox(height: TvMetrics.margin),
                  _Preview(settings: _crt),
                  const SizedBox(height: TvMetrics.margin),
                  _SliderRow(
                    sliderKey: textTvCrtCurveKey,
                    label: Messages.crtCurve,
                    value: _crt.curve,
                    max: crtCurveMax,
                    text: _percent(_crt.curve, 0, crtCurveMax),
                    onChanged: on
                        ? (double v) => _set(_crt.copyWith(curve: v))
                        : null,
                  ),
                  _SliderRow(
                    sliderKey: textTvCrtDepthKey,
                    label: Messages.crtScanDepth,
                    value: _crt.scanDepth,
                    max: crtScanDepthMax,
                    text: _percent(_crt.scanDepth, 0, crtScanDepthMax),
                    onChanged: on
                        ? (double v) => _set(_crt.copyWith(scanDepth: v))
                        : null,
                  ),
                  _SliderRow(
                    sliderKey: textTvCrtPeriodKey,
                    label: Messages.crtScanPeriod,
                    value: _crt.scanPeriod,
                    min: crtScanPeriodMin,
                    max: crtScanPeriodMax,
                    text: Messages.pixels(_crt.scanPeriod),
                    onChanged: on
                        ? (double v) => _set(_crt.copyWith(scanPeriod: v))
                        : null,
                  ),
                  const SizedBox(height: TvMetrics.margin),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TvButton(
                      key: textTvCrtResetKey,
                      label: Messages.reset,
                      onTap: on ? () => _set(_crt.reset()) : null,
                    ),
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

class _SwitchRow extends StatelessWidget {
  const _SwitchRow({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      label: label,
      toggled: value,
      child: Row(
        children: <Widget>[
          Expanded(
            child: ExcludeSemantics(
              child: Text(label, style: tvText(12, TvColors.white)),
            ),
          ),
          Switch(
            key: textTvCrtSwitchKey,
            value: value,
            onChanged: onChanged,
            activeThumbColor: TvColors.black,
            activeTrackColor: TvColors.highlight,
            inactiveThumbColor: TvColors.white,
            inactiveTrackColor: TvColors.black,
            trackOutlineColor: WidgetStatePropertyAll<Color>(
              value ? TvColors.highlight : TvColors.border,
            ),
          ),
        ],
      ),
    );
  }
}

class _SliderRow extends StatelessWidget {
  const _SliderRow({
    required this.sliderKey,
    required this.label,
    required this.value,
    required this.text,
    required this.onChanged,
    this.min = 0,
    required this.max,
  });

  final Key sliderKey;
  final String label;
  final double value;
  final double min;
  final double max;

  /// The value as shown next to the label.
  final String text;

  /// Null greys the slider, for when the effect is off.
  final ValueChanged<double>? onChanged;

  @override
  Widget build(BuildContext context) {
    final Color colour = onChanged == null ? TvColors.dim : TvColors.white;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            Expanded(child: Text(label, style: tvText(10, colour))),
            Text(text, style: tvText(10, colour)),
          ],
        ),
        SliderTheme(
          data: SliderThemeData(
            activeTrackColor: TvColors.highlight,
            inactiveTrackColor: TvColors.border,
            thumbColor: TvColors.highlight,
            disabledActiveTrackColor: TvColors.dim,
            disabledInactiveTrackColor: TvColors.border,
            disabledThumbColor: TvColors.dim,
            overlayColor: TvColors.highlight.withValues(alpha: 0.2),
            trackHeight: 4,
          ),
          child: Slider(
            key: sliderKey,
            value: value.clamp(min, max),
            min: min,
            max: max,
            divisions: 20,
            semanticFormatterCallback: (double v) => '$label $text',
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }
}

/// A few rows of teletext, drawn as the page will be, so a slider can be
/// judged where it is moved.
class _Preview extends StatelessWidget {
  const _Preview({required this.settings});

  final CrtSettings settings;

  static const TextStyle _style = TextStyle(
    fontFamily: kPixelFontFamily,
    fontSize: 8,
    height: 1.6,
    leadingDistribution: TextLeadingDistribution.even,
  );

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
              style: _style,
              gutterLeft: tvGutterCells ~/ 2,
            ),
        ],
      ),
    );
    return Semantics(
      label: Messages.crtPreview,
      excludeSemantics: true,
      child: Container(
        key: textTvCrtPreviewKey,
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
