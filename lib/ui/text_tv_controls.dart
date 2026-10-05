import 'package:codedbykay_text_tv/messages.dart';
import 'package:codedbykay_text_tv/ui/glasses_icon.dart';
import 'package:codedbykay_text_tv/ui/text_tv_keys.dart';
import 'package:codedbykay_text_tv/ui/theme.dart';
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
  });

  final VoidCallback? onRefresh;

  /// Whether the page is shown as reader text, and the button that switches.
  final bool readerOn;
  final VoidCallback onReader;

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

/// A bordered button with an icon, lit when [selected].
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
  final VoidCallback onTap;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final Color colour = selected ? TvColors.highlight : TvColors.white;
    return Semantics(
      button: true,
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

/// A number pad, like a remote's: 1 to 9, then DEL, 0, and a key that puts it
/// away. The third digit opens the page.
class TvKeypad extends StatelessWidget {
  const TvKeypad({
    super.key,
    required this.onDigit,
    required this.onDelete,
    required this.onClose,
  });

  final ValueChanged<int> onDigit;
  final VoidCallback onDelete;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    Widget key(Key key, String label, VoidCallback onTap) => Expanded(
      child: Padding(
        padding: const EdgeInsets.all(2),
        child: TvButton(key: key, label: label, onTap: onTap),
      ),
    );
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        for (final int row in <int>[0, 1, 2])
          Row(
            children: <Widget>[
              for (final int digit in <int>[
                row * 3 + 1,
                row * 3 + 2,
                row * 3 + 3,
              ])
                key(textTvDigitKey(digit), '$digit', () => onDigit(digit)),
            ],
          ),
        Row(
          children: <Widget>[
            key(textTvDeleteKey, 'DEL', onDelete),
            key(textTvDigitKey(0), '0', () => onDigit(0)),
            key(textTvKeypadCloseKey, 'X', onClose),
          ],
        ),
      ],
    );
  }
}
