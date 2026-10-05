import 'package:codedbykay_text_tv/l10n/l10n.dart';
import 'package:codedbykay_text_tv/model/fastext.dart';
import 'package:codedbykay_text_tv/model/saved_pages.dart';
import 'package:codedbykay_text_tv/model/styled_text.dart';
import 'package:codedbykay_text_tv/ui/glasses_icon.dart';
import 'package:codedbykay_text_tv/ui/text_tv_keys.dart';
import 'package:codedbykay_text_tv/ui/theme.dart';
import 'package:codedbykay_text_tv/ui/tv_row.dart';
import 'package:flutter/material.dart';

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
    required this.onSearch,
  });

  final VoidCallback? onRefresh;

  /// Whether the page is shown as reader text, and the button that switches.
  final bool readerOn;
  final VoidCallback onReader;

  /// Opens the settings page.
  final VoidCallback onSettings;

  /// Opens the search.
  final VoidCallback onSearch;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.all(TvMetrics.gutter),
        child: Row(
          children: <Widget>[
            Expanded(
              // Four buttons leave a narrow phone little room: the title
              // shrinks to fit rather than being cut off.
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  context.l10n.title,
                  style: tvText(14, TvColors.white),
                  maxLines: 1,
                ),
              ),
            ),
            const SizedBox(width: TvMetrics.gutter),
            TvIconButton(
              key: textTvSearchKey,
              icon: (Color colour) =>
                  Icon(Icons.search, color: colour, size: 26),
              semanticLabel: context.l10n.search,
              onTap: onSearch,
            ),
            const SizedBox(width: TvMetrics.gutter),
            TvIconButton(
              key: textTvReaderKey,
              icon: (Color colour) => GlassesIcon(colour: colour),
              selected: readerOn,
              semanticLabel: readerOn
                  ? context.l10n.readerOff
                  : context.l10n.readerOn,
              onTap: onReader,
            ),
            const SizedBox(width: TvMetrics.gutter),
            TvIconButton(
              key: textTvSettingsKey,
              icon: (Color colour) =>
                  Icon(Icons.settings, color: colour, size: 26),
              semanticLabel: context.l10n.settings,
              onTap: onSettings,
            ),
            const SizedBox(width: TvMetrics.gutter),
            TvIconButton(
              key: textTvRefreshKey,
              icon: (Color colour) =>
                  Icon(Icons.refresh, color: colour, size: 26),
              semanticLabel: context.l10n.refreshPage,
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

/// One dim line under the page saying when it was last read from the site.
class TvUpdatedNote extends StatelessWidget {
  const TvUpdatedNote({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: TvMetrics.gutter),
      child: Text(
        text,
        key: textTvUpdatedKey,
        style: tvText(8, TvColors.dim),
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
            '${context.l10n.part} ${part + 1}/$parts',
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
  const TvShortcuts({
    super.key,
    required this.favourites,
    required this.current,
    required this.onOpen,
    required this.onRecents,
    this.onNews,
  });

  /// Opens the list of pages read last: the chip that starts the row.
  final VoidCallback onRecents;

  /// Opens the lists of what is new (the chip after that one); none without it.
  final VoidCallback? onNews;

  /// The chips, in order.
  final List<Favourite> favourites;
  final int current;
  final ValueChanged<int> onOpen;

  @override
  Widget build(BuildContext context) {
    final Widget history = InkWell(
      key: textTvRecentsKey,
      onTap: onRecents,
      child: Semantics(
        button: true,
        label: context.l10n.recentPages,
        excludeSemantics: true,
        child: Container(
          constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            border: Border.all(color: TvColors.border, width: TvMetrics.border),
          ),
          child: const Icon(Icons.history, color: TvColors.white, size: 26),
        ),
      ),
    );
    final VoidCallback? openNews = onNews;
    final List<Widget> starters = <Widget>[
      history,
      const SizedBox(width: TvMetrics.gutter),
      if (openNews != null) ...<Widget>[
        InkWell(
          key: textTvNewsKey,
          onTap: openNews,
          child: Semantics(
            button: true,
            label: context.l10n.newsLabel,
            excludeSemantics: true,
            child: Container(
              constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                border: Border.all(
                  color: TvColors.border,
                  width: TvMetrics.border,
                ),
              ),
              child: const Icon(
                Icons.newspaper,
                color: TvColors.white,
                size: 26,
              ),
            ),
          ),
        ),
        const SizedBox(width: TvMetrics.gutter),
      ],
    ];
    if (favourites.isEmpty) {
      return Row(
        children: <Widget>[
          ...starters,
          Expanded(
            child: Text(
              context.l10n.favouritesHint,
              key: textTvFavouritesHintKey,
              style: tvText(8, TvColors.dim),
            ),
          ),
        ],
      );
    }
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: <Widget>[
          ...starters,
          for (final Favourite favourite in favourites) ...<Widget>[
            InkWell(
              key: textTvChipKey(favourite.page),
              onTap: () => onOpen(favourite.page),
              child: Container(
                constraints: const BoxConstraints(minHeight: 48),
                alignment: Alignment.center,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: favourite.page == current
                        ? TvColors.highlight
                        : TvColors.border,
                    width: TvMetrics.border,
                  ),
                ),
                child: Text(
                  context.l10n.chipLabel(favourite),
                  style: tvText(
                    10,
                    favourite.page == current
                        ? TvColors.highlight
                        : TvColors.white,
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
      label: '${link.label}. ${context.l10n.pageLabel(link.page)}',
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

/// The classic number pad, like a remote's: 1 to 9, then DEL, 0, and a key that
/// puts it away. The third digit opens the page. Opened by tapping the number
/// box when the quick pad is off (see `ControlsSettings`).
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
