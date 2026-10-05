import 'package:codedbykay_text_tv/messages.dart';
import 'package:codedbykay_text_tv/model/styled_text.dart';
import 'package:codedbykay_text_tv/model/text_tv_page.dart';
import 'package:codedbykay_text_tv/model/tv_layout.dart';
import 'package:codedbykay_text_tv/ui/text_tv_controls.dart';
import 'package:codedbykay_text_tv/ui/text_tv_keys.dart';
import 'package:codedbykay_text_tv/ui/theme.dart';
import 'package:codedbykay_text_tv/ui/tv_row.dart';
import 'package:flutter/material.dart';

/// The page itself, on its own black screen: coloured rows, or a word about why
/// there are none.
class TvPageArea extends StatelessWidget {
  const TvPageArea({
    super.key,
    required this.number,
    required this.part,
    required this.loading,
    required this.result,
    required this.onLink,
    required this.onRetry,
    this.onPull,
  });

  /// Called when the page is pulled down past its top; the future ends when
  /// the page has been read again. Without it pulling does nothing.
  final Future<void> Function()? onPull;

  final int number;
  final int part;
  final bool loading;
  final TextTvResult? result;
  final ValueChanged<String> onLink;
  final VoidCallback onRetry;

  /// Black space above and below the page.
  static const double _airAbove = TvMetrics.margin;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final TextTvResult? shown = result;
        final Widget content;
        if (loading || shown == null) {
          content = TvMessage(lines: const <String>[Messages.loading]);
        } else {
          content = switch (shown) {
            TextTvShown(:final TextTvPage page) => TvGrid(
              page: page,
              part: part,
              onLink: onLink,
              width: constraints.maxWidth,
              height: constraints.maxHeight - 2 * _airAbove,
            ),
            TextTvNotBroadcast(:final int number) => TvMessage(
              lines: <String>[Messages.pageNotBroadcast(number)],
            ),
            TextTvFailed(:final String reason) => TvMessage(
              lines: <String>[reason.toUpperCase()],
              retry: onRetry,
            ),
          };
        }
        final Widget scroll = SingleChildScrollView(
          // A page that fits still has to be pullable.
          physics: onPull == null
              ? null
              : const AlwaysScrollableScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Padding(
              // Air above and below the page, so the first row is not pressed
              // against the bar over it nor the last against the controls.
              padding: const EdgeInsets.symmetric(vertical: _airAbove),
              child: Center(child: content),
            ),
          ),
        );
        final Future<void> Function()? pull = onPull;
        return pull == null
            ? scroll
            : RefreshIndicator(
                color: TvColors.highlight,
                backgroundColor: TvColors.black,
                onRefresh: pull,
                child: scroll,
              );
      },
    );
  }
}

class TvMessage extends StatelessWidget {
  const TvMessage({super.key, required this.lines, this.retry});

  final List<String> lines;
  final VoidCallback? retry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(TvMetrics.margin * 2),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          for (final String line in lines)
            Text(
              line,
              style: tvText(10, TvColors.white),
              textAlign: TextAlign.center,
            ),
          if (retry != null) ...<Widget>[
            const SizedBox(height: TvMetrics.margin),
            TvButton(
              key: textTvRetryKey,
              label: Messages.tryAgain,
              onTap: retry,
            ),
          ],
        ],
      ),
    );
  }
}

/// The grid of one part of a page, drawn edge to edge with the text
/// centred between equal margins.
class TvGrid extends StatelessWidget {
  const TvGrid({
    super.key,
    required this.page,
    required this.part,
    required this.onLink,
    required this.width,
    required this.height,
  });

  final TextTvPage page;
  final int part;
  final ValueChanged<String> onLink;

  /// The room the page has, so its rows can be made tall enough to fill it.
  final double width;
  final double height;

  /// No row is drawn taller than this many cells: on a very tall screen the
  /// page stops growing and is centred instead.
  static const double _tallestRow = 3;

  @override
  Widget build(BuildContext context) {
    final int index = part.clamp(0, page.parts.length - 1);
    // The coloured version when the site sent one, else the plain text on the
    // same grid.
    final List<List<StyledRun>> rows =
        page.styledParts?[index] ??
        <List<StyledRun>>[
          for (final String line in page.parts[index])
            <StyledRun>[StyledRun(line.padRight(textTvColumns))],
        ];
    final ({int left, int right}) gutters = tvGutters(
      rows,
      columns: textTvColumns,
    );
    // Press Start 2P is a monospaced pixel face: every cell one square em. The
    // line height gives the rows their natural teletext proportions.
    const TextStyle style = TextStyle(
      fontFamily: kPixelFontFamily,
      fontSize: 8,
      height: 1.6,
      // The extra line height goes half above and half below the letters.
      // Left to the font's own split it all went above, so text sat low in its
      // row and its descenders ran into the row below.
      leadingDistribution: TextLeadingDistribution.even,
    );

    // Spread the rows over the height there is: a headline row counts for two.
    // A screen too short for the natural row height scrolls instead.
    final double cell = tvCellWidth(width);
    final int units = rows.fold(
      0,
      (int sum, List<StyledRun> row) =>
          sum + (row.any((StyledRun r) => r.tall) ? 2 : 1),
    );
    final double rowHeight = units == 0
        ? cell * 1.6
        : (height / units).clamp(cell * 1.6, cell * _tallestRow);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        for (final List<StyledRun> row in rows)
          TvRow(
            runs: row,
            columns: textTvColumns,
            style: style,
            // The text is centred by what it says; a bar, which runs the width
            // of the page, by its edges, so it has the same margin both sides.
            gutterLeft: tvIsBar(row, columns: textTvColumns)
                ? tvGutterCells ~/ 2
                : gutters.left,
            rowHeight: rowHeight,
            onRun: onLink,
          ),
      ],
    );
  }
}
