import 'package:codedbykay_text_tv/model/styled_text.dart';
import 'package:codedbykay_text_tv/model/text_tv_page.dart';
import 'package:codedbykay_text_tv/model/tv_layout.dart';

/// A stretch of text in a reader block; [page] makes it a link to that page.
class ReaderSpan {
  const ReaderSpan(this.text, {this.page});

  final String text;
  final int? page;
}

/// One piece of a page for the reader: what the page's 40-column rows come to
/// once headlines, wrapped text, link lists and tables are told apart.
sealed class ReaderBlock {
  const ReaderBlock();
}

/// The page's own first line (`100 SVT Text lördag 26 sep 2026`).
class ReaderCaption extends ReaderBlock {
  const ReaderCaption(this.text);

  final String text;
}

/// A headline or section banner. [link], when set, is the page the story is
/// on.
class ReaderHeading extends ReaderBlock {
  const ReaderHeading(this.spans, {this.link});

  final List<ReaderSpan> spans;
  final int? link;

  String get text => spans.map((ReaderSpan s) => s.text).join();
}

/// Running text: the lines of the page that wrapped into one, with the page
/// the story continues on as [link] when the page names one.
class ReaderParagraph extends ReaderBlock {
  const ReaderParagraph(this.spans, {this.link});

  final List<ReaderSpan> spans;
  final int? link;

  String get text => spans.map((ReaderSpan s) => s.text).join();
}

/// A table row: something on the left, a score or a time on the right.
class ReaderColumns extends ReaderBlock {
  const ReaderColumns(this.left, this.right);

  final String left;
  final String right;
}

/// A row of links to other pages (`Inrikes 101  Utrikes 104`).
class ReaderNav extends ReaderBlock {
  const ReaderNav(this.links);

  final List<ReaderLink> links;
}

class ReaderLink {
  const ReaderLink(this.label, this.page);

  final String label;
  final int page;
}

final RegExp _bareNumber = RegExp(r'^[1-8]\d\d$');
final RegExp _captionRow = RegExp(r'^[1-8]\d\d\s');
final RegExp _trailingNumber = RegExp(r'^(.+?)[\s.]*\s([1-8]\d\d)$');
final RegExp _navPair = RegExp(r'([^\d]+?)\s*([1-8]\d\d)(?=\s|$)');
final RegExp _navRow = RegExp(r'^(?:[^\d]+?\s*[1-8]\d\d\s*)+$');
final RegExp _gap = RegExp(r'\S( {3,})\S');
final RegExp _spaces = RegExp(r'\s+');

/// A line shorter than this (in characters) ended its sentence or its
/// heading: what follows starts something new rather than continuing it.
const int _wrapAt = 24;

/// Reflows part [part] of [page] for reading. The rules are about what
/// Text TV does, not about any one page:
///
/// - the first row is a [ReaderCaption];
/// - a blank row ends the text so far;
/// - a double-height row or a colour bar with text is a [ReaderHeading], and
///   the plain line directly above it belongs to it (a headline can start on
///   a normal-height row);
/// - a row of nothing but a page number links the block above it to that page;
/// - a row that is only `label number` pairs is a [ReaderNav];
/// - a line ending in a page number is its own linked paragraph (leader dots
///   dropped);
/// - a line with a wide gap in it is a [ReaderColumns] row;
/// - other lines join into a paragraph, unless the line before was short.
///
/// Uses the coloured rows when the site sent them (they know which rows are
/// tall and which are links), otherwise the plain text.
List<ReaderBlock> buildReaderBlocks(TextTvPage page, int part) {
  if (page.parts.isEmpty) return const <ReaderBlock>[];
  final int index = part.clamp(0, page.parts.length - 1);
  final List<List<StyledRun>> rows =
      page.styledParts?[index] ??
      <List<StyledRun>>[
        for (final String line in page.parts[index])
          <StyledRun>[StyledRun(line)],
      ];

  final List<ReaderBlock> blocks = <ReaderBlock>[];
  List<ReaderSpan>? open;
  int openLength = 0;
  bool afterHeading = false;

  void flush() {
    final List<ReaderSpan>? spans = open;
    if (spans != null) blocks.add(ReaderParagraph(spans));
    open = null;
  }

  void link(int page) {
    flush();
    if (blocks.isEmpty) return;
    final ReaderBlock last = blocks.last;
    if (last is ReaderHeading && last.link == null) {
      blocks[blocks.length - 1] = ReaderHeading(last.spans, link: page);
    } else if (last is ReaderParagraph && last.link == null) {
      blocks[blocks.length - 1] = ReaderParagraph(last.spans, link: page);
    }
  }

  for (int i = 0; i < rows.length; i++) {
    final List<StyledRun> runs = rows[i];
    final String text = plainText(runs).trim();

    if (i == 0 && _captionRow.hasMatch(text)) {
      blocks.add(ReaderCaption(text.replaceAll(_spaces, ' ')));
      continue;
    }
    if (text.isEmpty) {
      flush();
      afterHeading = false;
      continue;
    }
    if (_bareNumber.hasMatch(text)) {
      link(int.parse(text));
      afterHeading = false;
      continue;
    }
    final List<ReaderLink>? nav = _navLinks(text);
    if (nav != null) {
      flush();
      blocks.add(ReaderNav(nav));
      afterHeading = false;
      continue;
    }

    final List<ReaderSpan> spans = _spansOf(runs);
    final bool heading =
        runs.any((StyledRun r) => r.tall) ||
        tvIsBar(runs, columns: textTvColumns);
    if (heading) {
      final List<ReaderSpan>? above = open;
      final ReaderBlock? last = blocks.isEmpty ? null : blocks.last;
      if (afterHeading && last is ReaderHeading) {
        blocks[blocks.length - 1] = ReaderHeading(_join(last.spans, spans));
      } else if (above != null) {
        open = null;
        blocks.add(ReaderHeading(_join(above, spans)));
      } else {
        blocks.add(ReaderHeading(spans));
      }
      afterHeading = true;
      continue;
    }
    afterHeading = false;

    // Where the site marked its links, only a marked number ends a linked
    // line; a sentence that happens to end in 500 is just a sentence.
    final RegExpMatch? ending =
        page.styledParts == null || _endsInLinkedNumber(spans)
        ? _trailingNumber.firstMatch(text)
        : null;
    if (ending != null) {
      final List<ReaderSpan> item = _withoutTrailingNumber(spans, ending[1]!);
      final List<ReaderSpan>? above = open;
      open = null;
      blocks.add(
        ReaderParagraph(
          above == null ? item : _join(above, item),
          link: int.parse(ending[2]!),
        ),
      );
      continue;
    }

    final RegExpMatch? gap = _lastGap(text);
    if (gap != null) {
      flush();
      blocks.add(
        ReaderColumns(
          text.substring(0, gap.start + 1).replaceAll(_spaces, ' '),
          text.substring(gap.end - 1).replaceAll(_spaces, ' '),
        ),
      );
      continue;
    }

    final List<ReaderSpan>? above = open;
    if (above != null && openLength >= _wrapAt) {
      open = _join(above, spans);
    } else {
      flush();
      open = spans;
    }
    openLength = text.length;
  }
  flush();
  return blocks;
}

/// The widest gap in [text] counted from the right, as a match whose first
/// and last characters are the text on either side of it.
RegExpMatch? _lastGap(String text) {
  RegExpMatch? last;
  for (final RegExpMatch m in _gap.allMatches(text)) {
    last = m;
  }
  return last;
}

/// The links in a row that is nothing but `label number` pairs, else null.
List<ReaderLink>? _navLinks(String text) {
  if (!_navRow.hasMatch(text)) return null;
  final List<ReaderLink> links = <ReaderLink>[
    for (final RegExpMatch m in _navPair.allMatches(text))
      ReaderLink(
        m[1]!.replaceAll(RegExp(r'[*.]'), '').replaceAll(_spaces, ' ').trim(),
        int.parse(m[2]!),
      ),
  ];
  return links.length >= 2 ? links : null;
}

bool _endsInLinkedNumber(List<ReaderSpan> spans) =>
    spans.length > 1 &&
    spans.last.page != null &&
    _bareNumber.hasMatch(spans.last.text.trim());

/// [spans] without the page number that ends the line (a link run when the
/// site marked it, else cut from the text) and the leader dots before it;
/// [lead] is the line's text up to there, for when there are no runs to cut.
List<ReaderSpan> _withoutTrailingNumber(List<ReaderSpan> spans, String lead) {
  final List<ReaderSpan> kept = _endsInLinkedNumber(spans)
      ? spans.sublist(0, spans.length - 1)
      : <ReaderSpan>[ReaderSpan(lead)];
  final ReaderSpan end = kept.last;
  kept[kept.length - 1] = ReaderSpan(
    end.text.replaceAll(RegExp(r'[\s.]+$'), ''),
    page: end.page,
  );
  return <ReaderSpan>[
    for (final ReaderSpan s in kept)
      if (s.text.isNotEmpty) s,
  ];
}

List<ReaderSpan> _join(List<ReaderSpan> a, List<ReaderSpan> b) => <ReaderSpan>[
  ...a,
  const ReaderSpan(' '),
  ...b,
];

/// The text of a row's runs as spans, links kept, block graphics left out,
/// runs of spaces squeezed to one and the ends trimmed.
List<ReaderSpan> _spansOf(List<StyledRun> runs) {
  final List<ReaderSpan> spans = <ReaderSpan>[];
  for (final StyledRun run in runs) {
    if (run.mosaic != null) continue;
    final String text = run.text.replaceAll(_spaces, ' ');
    if (text.isEmpty) continue;
    final int? page = run.command == null ? null : int.tryParse(run.command!);
    if (spans.isNotEmpty && spans.last.page == page) {
      spans[spans.length - 1] = ReaderSpan(spans.last.text + text, page: page);
    } else {
      spans.add(ReaderSpan(text, page: page));
    }
  }
  if (spans.isEmpty) return spans;
  spans[0] = ReaderSpan(spans.first.text.trimLeft(), page: spans.first.page);
  final int last = spans.length - 1;
  spans[last] = ReaderSpan(
    spans[last].text.trimRight(),
    page: spans[last].page,
  );
  return <ReaderSpan>[
    for (final ReaderSpan s in spans)
      if (s.text.isNotEmpty) s,
  ];
}
