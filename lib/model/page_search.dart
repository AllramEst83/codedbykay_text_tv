import 'package:codedbykay_text_tv/model/text_tv_page.dart';

/// Fewest characters a search needs before it looks: one letter matches
/// nearly everything.
const int minSearchLength = 2;

/// Most hits a search gives back; the list is for picking from, not reading.
const int maxSearchHits = 30;

/// A page that has the searched words, with the line that has them.
class SearchHit {
  const SearchHit({
    required this.page,
    required this.line,
    required this.matches,
  });

  final int page;

  /// The first line that matches, with its spaces tidied, as shown.
  final String line;

  /// How many lines of the page match: the more, the likelier it is about it.
  final int matches;

  @override
  bool operator ==(Object other) =>
      other is SearchHit &&
      other.page == page &&
      other.line == line &&
      other.matches == matches;

  @override
  int get hashCode => Object.hash(page, line, matches);
}

/// [text] in a form to compare: lower case, and the Swedish letters without
/// their marks (å, ä, ö, é), so "skane" finds "Skåne" and the other way round.
String foldForSearch(String text) {
  const Map<String, String> plain = <String, String>{
    'å': 'a',
    'ä': 'a',
    'ö': 'o',
    'é': 'e',
    'è': 'e',
    'ü': 'u',
  };
  final StringBuffer out = StringBuffer();
  for (final int rune in text.toLowerCase().runes) {
    final String char = String.fromCharCode(rune);
    out.write(plain[char] ?? char);
  }
  return out.toString();
}

final RegExp _spaces = RegExp(r'\s+');

/// The pages in [pages] that have every word of [query] on one line (any case,
/// any order), best first: most matching lines, then lowest page number. Empty
/// for a query shorter than [minSearchLength]. A page is listed once, however
/// many parts it has. At most [maxSearchHits].
List<SearchHit> searchPages(Iterable<TextTvPage> pages, String query) {
  final List<String> words = foldForSearch(query)
      .split(_spaces)
      .where((String w) => w.isNotEmpty)
      .toList();
  if (words.isEmpty || words.join(' ').length < minSearchLength) {
    return const <SearchHit>[];
  }
  final List<SearchHit> hits = <SearchHit>[];
  for (final TextTvPage page in pages) {
    String? first;
    int matches = 0;
    for (final List<String> part in page.parts) {
      for (final String row in part) {
        final String folded = foldForSearch(row);
        if (words.every(folded.contains)) {
          matches++;
          first ??= row.trim().replaceAll(_spaces, ' ');
        }
      }
    }
    if (first != null) {
      hits.add(SearchHit(page: page.number, line: first, matches: matches));
    }
  }
  hits.sort((SearchHit a, SearchHit b) {
    final int byMatches = b.matches.compareTo(a.matches);
    return byMatches != 0 ? byMatches : a.page.compareTo(b.page);
  });
  return hits.length > maxSearchHits ? hits.sublist(0, maxSearchHits) : hits;
}
