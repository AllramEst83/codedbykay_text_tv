import 'package:codedbykay_text_tv/l10n/l10n.dart';
import 'package:codedbykay_text_tv/model/reader_settings.dart';
import 'package:codedbykay_text_tv/ui/formats.dart';
import 'package:codedbykay_text_tv/ui/text_tv_controls.dart';
import 'package:codedbykay_text_tv/ui/text_tv_keys.dart';
import 'package:codedbykay_text_tv/ui/theme.dart';
import 'package:codedbykay_text_tv/ui/tv_option_rows.dart';
import 'package:flutter/material.dart';

/// Opens the reader's layout options over the page: line spacing, letter
/// spacing, margins and bold. Each applies as it is moved, so the text behind
/// shows the change, and [onChanged] hears every one.
Future<void> showReaderOptions(
  BuildContext context, {
  required ReaderSettings settings,
  required ValueChanged<ReaderSettings> onChanged,
}) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: TvColors.black,
    barrierColor: Colors.black38,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(),
    builder: (BuildContext context) =>
        ReaderOptionsSheet(settings: settings, onChanged: onChanged),
  );
}

/// The options themselves; holds its own copy of the settings so its controls
/// move at once, and reports each change.
class ReaderOptionsSheet extends StatefulWidget {
  const ReaderOptionsSheet({
    super.key,
    required this.settings,
    required this.onChanged,
  });

  final ReaderSettings settings;
  final ValueChanged<ReaderSettings> onChanged;

  @override
  State<ReaderOptionsSheet> createState() => _ReaderOptionsSheetState();
}

class _ReaderOptionsSheetState extends State<ReaderOptionsSheet> {
  late ReaderSettings _settings = widget.settings;

  void _set(ReaderSettings settings) {
    setState(() => _settings = settings);
    widget.onChanged(settings);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        decoration: const BoxDecoration(
          border: Border(
            top: BorderSide(color: TvColors.border, width: TvMetrics.border),
          ),
        ),
        padding: const EdgeInsets.all(TvMetrics.margin),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              context.l10n.readerOptionsTitle,
              style: tvText(12, TvColors.white),
            ),
            const SizedBox(height: TvMetrics.margin),
            TvSliderRow(
              sliderKey: textTvReaderLineKey,
              label: context.l10n.lineSpacing,
              value: _settings.lineSpacing.toDouble(),
              max: (readerLineHeights.length - 1).toDouble(),
              divisions: readerLineHeights.length - 1,
              text: Formats.times(_settings.lineHeight),
              onChanged: (double v) =>
                  _set(_settings.copyWith(lineSpacing: v.round())),
            ),
            TvSliderRow(
              sliderKey: textTvReaderLetterKey,
              label: context.l10n.letterSpacing,
              value: _settings.letterSpacing.toDouble(),
              max: (readerLetterSpacings.length - 1).toDouble(),
              divisions: readerLetterSpacings.length - 1,
              text: Formats.percent(_settings.letterSpacingEm),
              onChanged: (double v) =>
                  _set(_settings.copyWith(letterSpacing: v.round())),
            ),
            TvSliderRow(
              sliderKey: textTvReaderMarginKey,
              label: context.l10n.margins,
              value: _settings.margin.toDouble(),
              max: (readerMargins.length - 1).toDouble(),
              divisions: readerMargins.length - 1,
              text: Formats.logicalPixels(_settings.marginWidth),
              onChanged: (double v) =>
                  _set(_settings.copyWith(margin: v.round())),
            ),
            const SizedBox(height: TvMetrics.gutter),
            Text(context.l10n.readerFont, style: tvText(12, TvColors.white)),
            const SizedBox(height: TvMetrics.gutter),
            Row(
              children: <Widget>[
                for (final ReaderFont font in ReaderFont.values)
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(
                        right: font == ReaderFont.values.last
                            ? 0
                            : TvMetrics.gutter,
                      ),
                      child: _FontChoice(
                        font: font,
                        selected: _settings.font == font,
                        onTap: () => _set(_settings.copyWith(font: font)),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: TvMetrics.margin),
            TvSwitchRow(
              switchKey: textTvReaderBoldKey,
              label: context.l10n.boldText,
              value: _settings.bold,
              onChanged: (bool v) => _set(_settings.copyWith(bold: v)),
            ),
            const SizedBox(height: TvMetrics.margin),
            TvButton(
              key: textTvReaderResetKey,
              label: context.l10n.reset,
              onTap: () => _set(_settings.resetLayout()),
            ),
          ],
        ),
      ),
    );
  }
}

/// One typeface to pick, its name set in it so it can be judged by looking.
class _FontChoice extends StatelessWidget {
  const _FontChoice({
    required this.font,
    required this.selected,
    required this.onTap,
  });

  final ReaderFont font;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final String name = context.l10n.fontName(font);
    final Color colour = selected ? TvColors.highlight : TvColors.white;
    return Semantics(
      button: true,
      selected: selected,
      label: name,
      excludeSemantics: true,
      child: InkWell(
        key: textTvReaderFontKey(font),
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: 48),
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            border: Border.all(
              color: selected ? TvColors.highlight : TvColors.border,
              width: TvMetrics.border,
            ),
          ),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              name,
              style: readerTextStyle(
                14,
                colour,
                weight: FontWeight.w700,
                height: 1.2,
                font: font,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
