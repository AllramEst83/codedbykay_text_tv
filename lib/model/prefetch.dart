import 'package:codedbykay_text_tv/model/fastext.dart';
import 'package:codedbykay_text_tv/model/styled_text.dart';
import 'package:codedbykay_text_tv/model/text_tv_page.dart';

/// The most pages read ahead for one page on screen. A small number on
/// purpose: texttv.nu documents no rate limit, and each page viewed already
/// costs the site one request.
const int prefetchLimit = 4;

/// The pages worth reading before they are asked for, for part [part] of
/// [page]: the ones a reader goes to next, most likely first. The page after,
/// the page before (the site's own neighbours, else the numbers either side),
/// then the pages the page links to, in the order it links them. Each at most
/// once, never the page itself, only real page numbers, and no more than
/// [limit].
List<int> prefetchTargets(
  TextTvPage page,
  int part, {
  int limit = prefetchLimit,
}) {
  final List<int> wanted = <int>[
    page.next ?? page.number + 1,
    page.previous ?? page.number - 1,
    ..._linked(page, part),
  ];
  final List<int> targets = <int>[];
  for (final int number in wanted) {
    if (targets.length >= limit) break;
    if (number == page.number) continue;
    if (number < textTvFirstPage || number > textTvLastPage) continue;
    if (!targets.contains(number)) targets.add(number);
  }
  return targets;
}

/// The page numbers the part links to: the ones the site marked as links in
/// the text, then the bottom row's (which a plain-text page has no marks for).
Iterable<int> _linked(TextTvPage page, int part) sync* {
  if (page.parts.isEmpty) return;
  final int index = part.clamp(0, page.parts.length - 1);
  final List<List<StyledRun>> rows =
      page.styledParts?[index] ?? const <List<StyledRun>>[];
  for (final List<StyledRun> row in rows) {
    for (final StyledRun run in row) {
      final int? number = run.command == null
          ? null
          : int.tryParse(run.command!);
      if (number != null) yield number;
    }
  }
  for (final FastextLink link in fastextLinks(page, part)) {
    yield link.page;
  }
}
