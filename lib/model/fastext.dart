import 'package:codedbykay_text_tv/model/reader_content.dart';
import 'package:codedbykay_text_tv/model/styled_text.dart';
import 'package:codedbykay_text_tv/model/text_tv_page.dart';

/// The four coloured keys of a teletext remote, in order.
enum FastextColour { red, green, yellow, blue }

/// One Fastext key: a colour, a short label and the page it opens.
class FastextLink {
  const FastextLink(this.colour, this.label, this.page);

  final FastextColour colour;
  final String label;
  final int page;
}

/// The Fastext keys of part [part] of [page]: its last row of text, when that
/// row is nothing but `label number` pairs (`Inrikes 101  Utrikes 104`), one
/// key for each, at most four, coloured red, green, yellow and blue in the
/// order they appear. Empty when the page has no such row.
///
/// Real teletext sends the keys' pages separately; texttv.nu does not, but
/// pages put the same links in their bottom row, so that row is read.
List<FastextLink> fastextLinks(TextTvPage page, int part) {
  if (page.parts.isEmpty) return const <FastextLink>[];
  final int index = part.clamp(0, page.parts.length - 1);
  final List<String> rows =
      page.styledParts?[index].map(plainText).toList() ?? page.parts[index];
  final String? last = rows
      .map((String row) => row.trim())
      .where((String row) => row.isNotEmpty)
      .lastOrNull;
  if (last == null) return const <FastextLink>[];
  final List<ReaderLink> links = readerNavLinks(last) ?? const <ReaderLink>[];
  return <FastextLink>[
    for (int i = 0; i < links.length && i < FastextColour.values.length; i++)
      FastextLink(FastextColour.values[i], links[i].label, links[i].page),
  ];
}
