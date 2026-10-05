import 'package:codedbykay_text_tv/model/text_tv_page.dart';

/// Where page [number] is on the web.
String pageLink(int number) => 'https://texttv.nu/$number';

/// What part [part] of [page] says, as plain text for pasting: the rows as
/// the page has them, with the empty ones at the top and bottom left off. The
/// rows' own spacing stays, so columns still line up in a fixed-width font.
String pageText(TextTvPage page, int part) {
  if (page.parts.isEmpty) return '';
  final List<String> rows = List<String>.of(
    page.parts[part.clamp(0, page.parts.length - 1)],
  );
  while (rows.isNotEmpty && rows.last.trim().isEmpty) {
    rows.removeLast();
  }
  int first = 0;
  while (first < rows.length && rows[first].trim().isEmpty) {
    first++;
  }
  return rows.sublist(first).join('\n');
}

/// The link to share for [page]: the one that names this version of it, when
/// the site gave one (what a page says changes by the hour, and a shared link
/// should show what was shared), else the page's own address.
String shareLinkFor(TextTvPage page) => page.permalink ?? pageLink(page.number);

/// The text to send to somebody: the page, and where to find it.
String shareMessage(TextTvPage page, int part) =>
    '${pageText(page, part)}\n\n${shareLinkFor(page)}';
