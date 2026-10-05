import 'package:codedbykay_text_tv/model/styled_text.dart';

/// Text TV pages are laid out on a grid this many characters wide.
const int textTvColumns = 40;

/// Text TV pages run from 100 to 899.
const int textTvFirstPage = 100;
const int textTvLastPage = 899;

/// One page of Swedish Text TV as plain text. A page can be several [parts]
/// (sub-pages), each a grid of up to [textTvColumns] characters per line.
class TextTvPage {
  const TextTvPage({
    required this.number,
    required this.parts,
    this.styledParts,
    this.previous,
    this.next,
  });

  final int number;

  /// Sub-pages in reading order; each is its lines, right-trimmed.
  final List<List<String>> parts;

  /// The same sub-pages with their colours, every row exactly
  /// [textTvColumns] wide (not trimmed: a coloured bar runs to the edge).
  /// Null when the site sent no colours or they could not be read, in which
  /// case [parts] is all there is. When set it has as many parts as [parts].
  final List<List<List<StyledRun>>>? styledParts;

  /// Neighbouring page numbers, when the service says what they are.
  final int? previous;
  final int? next;
}

/// What the viewer gets back for a page: the page, or why
/// there is none to show. A failure carries a short, printable sentence.
sealed class TextTvResult {
  const TextTvResult();
}

class TextTvShown extends TextTvResult {
  const TextTvShown(this.page, {this.cachedAt, this.readAt});

  final TextTvPage page;

  /// When this copy of the page was read from the site, if known: just now for
  /// a page read, the earlier time for one kept in memory or saved on disk.
  final DateTime? readAt;

  /// Set when the site could not be reached and this is the copy saved at that
  /// time instead. Null for a page just read.
  final DateTime? cachedAt;
}

/// The number is valid but not in broadcast.
class TextTvNotBroadcast extends TextTvResult {
  const TextTvNotBroadcast(this.number);

  final int number;
}

class TextTvFailed extends TextTvResult {
  const TextTvFailed(this.reason);

  final String reason;
}
