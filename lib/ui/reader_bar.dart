import 'package:codedbykay_text_tv/l10n/l10n.dart';
import 'package:codedbykay_text_tv/model/reader_settings.dart';
import 'package:codedbykay_text_tv/ui/reader_options_sheet.dart';
import 'package:codedbykay_text_tv/ui/text_tv_controls.dart';
import 'package:codedbykay_text_tv/ui/text_tv_keys.dart';
import 'package:codedbykay_text_tv/ui/theme.dart';
import 'package:flutter/material.dart';

/// The reader's controls under the top bar: text size down and up, and a
/// swatch for each colour scheme. Scrolls sideways on a phone too narrow for
/// all of it.
class ReaderBar extends StatelessWidget {
  const ReaderBar({super.key, required this.settings, required this.onChanged});

  final ReaderSettings settings;
  final ValueChanged<ReaderSettings> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: TvMetrics.margin),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: TvMetrics.gutter),
        child: Row(
          children: <Widget>[
            TvIconButton(
              key: textTvReaderSmallerKey,
              icon: (Color colour) => Text('A-', style: tvText(12, colour)),
              semanticLabel: context.l10n.smallerText,
              onTap: settings.size > 0
                  ? () => onChanged(settings.copyWith(size: settings.size - 1))
                  : null,
            ),
            const SizedBox(width: TvMetrics.gutter),
            TvIconButton(
              key: textTvReaderLargerKey,
              icon: (Color colour) => Text('A+', style: tvText(12, colour)),
              semanticLabel: context.l10n.largerText,
              onTap: settings.size < readerTextSizes.length - 1
                  ? () => onChanged(settings.copyWith(size: settings.size + 1))
                  : null,
            ),
            const SizedBox(width: TvMetrics.gutter),
            TvIconButton(
              key: textTvReaderOptionsKey,
              icon: (Color colour) => Icon(Icons.tune, color: colour, size: 26),
              semanticLabel: context.l10n.readerOptions,
              onTap: () => showReaderOptions(
                context,
                settings: settings,
                onChanged: onChanged,
              ),
            ),
            const SizedBox(width: TvMetrics.margin),
            for (final ReaderTheme theme in ReaderTheme.values)
              _Swatch(
                theme: theme,
                selected: theme == settings.theme,
                onTap: () => onChanged(settings.copyWith(theme: theme)),
              ),
          ],
        ),
      ),
    );
  }
}

class _Swatch extends StatelessWidget {
  const _Swatch({
    required this.theme,
    required this.selected,
    required this.onTap,
  });

  final ReaderTheme theme;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ReaderPalette palette = readerPalette(theme);
    return Semantics(
      button: true,
      selected: selected,
      label: context.l10n.themeName(theme),
      excludeSemantics: true,
      child: InkWell(
        key: textTvReaderThemeKey(theme),
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: 48,
          height: 48,
          child: Center(
            child: Container(
              width: 36,
              height: 36,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: palette.background,
                shape: BoxShape.circle,
                border: Border.all(
                  color: selected ? TvColors.highlight : palette.dim,
                  width: selected ? 3 : 2,
                ),
              ),
              child: Text(
                'A',
                style: readerTextStyle(
                  16,
                  palette.text,
                  weight: FontWeight.w700,
                  height: 1,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
