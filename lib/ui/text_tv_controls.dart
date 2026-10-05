import 'package:codedbykay_text_tv/messages.dart';
import 'package:codedbykay_text_tv/model/fastext.dart';
import 'package:codedbykay_text_tv/model/styled_text.dart';
import 'package:codedbykay_text_tv/ui/glasses_icon.dart';
import 'package:codedbykay_text_tv/ui/text_tv_keys.dart';
import 'package:codedbykay_text_tv/ui/theme.dart';
import 'package:codedbykay_text_tv/ui/tv_row.dart';
import 'package:flutter/material.dart';

/// The pages people actually open, one tap away.
const List<(int, String)> textTvShortcuts = <(int, String)>[
  (100, 'NYHETER'),
  (101, 'INRIKES'),
  (104, 'UTRIKES'),
  (300, 'SPORT'),
  (400, 'VÄDER'),
  (700, 'INNEHÅLL'),
];

TextStyle tvText(double size, Color colour) =>
    TextStyle(fontFamily: kPixelFontFamily, fontSize: size, color: colour);

/// The bar above the page: the name, and REFRESH.
class TvTopBar extends StatelessWidget {
  const TvTopBar({
    super.key,
    required this.onRefresh,
    required this.readerOn,
    required this.onReader,
    required this.onSettings,
  });

  final VoidCallback? onRefresh;

  /// Whether the page is shown as reader text, and the button that switches.
  final bool readerOn;
  final VoidCallback onReader;

  /// Opens the settings page.
  final VoidCallback onSettings;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.all(TvMetrics.gutter),
        child: Row(
          children: <Widget>[
            Expanded(
              child: Text(
                Messages.title,
                style: tvText(14, TvColors.white),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            TvIconButton(
              key: textTvReaderKey,
              icon: (Color colour) => GlassesIcon(colour: colour),
              selected: readerOn,
              semanticLabel: readerOn ? Messages.readerOff : Messages.readerOn,
              onTap: onReader,
            ),
            const SizedBox(width: TvMetrics.gutter),
            TvIconButton(
              key: textTvSettingsKey,
              icon: (Color colour) =>
                  Icon(Icons.settings, color: colour, size: 26),
              semanticLabel: Messages.settings,
              onTap: onSettings,
            ),
            const SizedBox(width: TvMetrics.gutter),
            TvButton(
              key: textTvRefreshKey,
              label: Messages.refresh,
              onTap: onRefresh,
            ),
          ],
        ),
      ),
    );
  }
}

/// One dim line under the page saying it is a saved copy, not the live page.
class TvOfflineNote extends StatelessWidget {
  const TvOfflineNote({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: TvMetrics.gutter),
      child: Text(
        text,
        key: textTvOfflineKey,
        style: tvText(8, TvColors.highlight),
        textAlign: TextAlign.center,
      ),
    );
  }
}

/// `[<] PART 2/3 [>]` under a page that has several.
class TvPartBar extends StatelessWidget {
  const TvPartBar({
    super.key,
    required this.part,
    required this.parts,
    required this.onPrevious,
    required this.onNext,
  });

  final int part;
  final int parts;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: TvMetrics.gutter),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          TvButton(key: textTvPartPrevKey, label: '<', onTap: onPrevious),
          const SizedBox(width: TvMetrics.margin),
          Text(
            '${Messages.part} ${part + 1}/$parts',
            style: tvText(10, TvColors.white),
          ),
          const SizedBox(width: TvMetrics.margin),
          TvButton(key: textTvPartNextKey, label: '>', onTap: onNext),
        ],
      ),
    );
  }
}

/// A bordered text button in the viewer's flat look; a `null` [onTap] greys it.
class TvButton extends StatelessWidget {
  const TvButton({
    super.key,
    required this.label,
    required this.onTap,
    this.semanticLabel,
  });

  final String label;
  final VoidCallback? onTap;

  /// What a screen reader says when the label is not words (`A+`).
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final Color colour = onTap == null ? TvColors.dim : TvColors.white;
    return InkWell(
      onTap: onTap,
      child: Container(
        // Big enough for a thumb, and to stay where a thumb expects it.
        constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          border: Border.all(color: colour, width: TvMetrics.border),
        ),
        child: Text(
          label,
          style: tvText(12, colour),
          semanticsLabel: semanticLabel,
        ),
      ),
    );
  }
}

/// A bordered square button with an icon or a short label drawn by [icon], lit
/// when [selected] and greyed when [onTap] is null.
class TvIconButton extends StatelessWidget {
  const TvIconButton({
    super.key,
    required this.icon,
    required this.semanticLabel,
    required this.onTap,
    this.selected = false,
  });

  /// Draws the icon in the colour the button is in just now.
  final Widget Function(Color colour) icon;
  final String semanticLabel;
  final VoidCallback? onTap;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final Color colour = onTap == null
        ? TvColors.dim
        : selected
        ? TvColors.highlight
        : TvColors.white;
    return Semantics(
      button: true,
      enabled: onTap != null,
      selected: selected,
      label: semanticLabel,
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            border: Border.all(color: colour, width: TvMetrics.border),
          ),
          child: icon(colour),
        ),
      ),
    );
  }
}

/// The current page number, big; tap it to type another with the number pad.
class TvNumberBox extends StatelessWidget {
  const TvNumberBox({
    super.key,
    required this.text,
    required this.active,
    required this.onTap,
  });

  final String text;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(minHeight: 48),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          border: Border.all(
            color: active ? TvColors.highlight : TvColors.border,
            width: TvMetrics.border,
          ),
        ),
        child: Text(
          text,
          style: tvText(20, active ? TvColors.highlight : TvColors.white),
        ),
      ),
    );
  }
}

/// Shortcuts to the pages people read, scrolling sideways.
class TvShortcuts extends StatelessWidget {
  const TvShortcuts({super.key, required this.current, required this.onOpen});

  final int current;
  final ValueChanged<int> onOpen;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: <Widget>[
          for (final (int page, String name) in textTvShortcuts) ...<Widget>[
            InkWell(
              key: textTvChipKey(page),
              onTap: () => onOpen(page),
              child: Container(
                constraints: const BoxConstraints(minHeight: 48),
                alignment: Alignment.center,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: page == current
                        ? TvColors.highlight
                        : TvColors.border,
                    width: TvMetrics.border,
                  ),
                ),
                child: Text(
                  '$page $name',
                  style: tvText(
                    10,
                    page == current ? TvColors.highlight : TvColors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(width: TvMetrics.gutter),
          ],
        ],
      ),
    );
  }
}

/// The digits, always at hand like a remote's: 1 to 5 over 6 to 9 and 0. A page
/// number starts with 1 to 8, so 0 and 9 are greyed until a first digit is in;
/// the third digit opens the page (the screen decides, [onDigit] only says
/// which key).
class TvDigitPad extends StatelessWidget {
  const TvDigitPad({super.key, required this.typed, required this.onDigit});

  /// What has been typed so far, `''` to `'12'`.
  final String typed;
  final ValueChanged<int> onDigit;

  static const List<List<int>> _rows = <List<int>>[
    <int>[1, 2, 3, 4, 5],
    <int>[6, 7, 8, 9, 0],
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        for (final List<int> row in _rows)
          Row(
            children: <Widget>[
              for (final int digit in row)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(2),
                    child: TvButton(
                      key: textTvDigitKey(digit),
                      label: '$digit',
                      onTap: typed.isEmpty && (digit < 1 || digit > 8)
                          ? null
                          : () => onDigit(digit),
                    ),
                  ),
                ),
            ],
          ),
      ],
    );
  }
}

/// The coloured keys under a page that has links in its bottom row: red,
/// green, yellow, blue, each with the page's own label over its number.
class TvFastext extends StatelessWidget {
  const TvFastext({super.key, required this.links, required this.onOpen});

  final List<FastextLink> links;
  final ValueChanged<int> onOpen;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        for (int i = 0; i < links.length; i++)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: _FastextKey(
                key: textTvFastextKey(i),
                link: links[i],
                onTap: () => onOpen(links[i].page),
              ),
            ),
          ),
      ],
    );
  }
}

class _FastextKey extends StatelessWidget {
  const _FastextKey({super.key, required this.link, required this.onTap});

  final FastextLink link;
  final VoidCallback onTap;

  static Color _fill(FastextColour colour) => tvColorOf(switch (colour) {
    FastextColour.red => TvColor.red,
    FastextColour.green => TvColor.green,
    FastextColour.yellow => TvColor.yellow,
    FastextColour.blue => TvColor.blue,
  });

  @override
  Widget build(BuildContext context) {
    final Color fill = _fill(link.colour);
    // Dark letters on the light colours, white on the dark ones.
    final Color ink = fill.computeLuminance() > 0.35
        ? TvColors.black
        : TvColors.white;
    return Semantics(
      button: true,
      label: '${link.label}. ${Messages.pageLabel(link.page)}',
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: 48),
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
          color: fill,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(
                link.label,
                style: tvText(8, ink),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text('${link.page}', style: tvText(12, ink)),
            ],
          ),
        ),
      ),
    );
  }
}
