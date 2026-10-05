import 'package:codedbykay_text_tv/model/feed.dart';
import 'package:codedbykay_text_tv/model/page_search.dart';
import 'package:codedbykay_text_tv/model/text_tv_page.dart';

/// Text TV pages for the viewer. Never throws: every
/// failure is a [TextTvResult] that says why.
abstract interface class TextTvRepository {
  /// Page [number] (100 to 899). A page read a few minutes ago may be reused
  /// (going back to a page just left must not fetch it again); [fresh]
  /// insists on asking the site.
  Future<TextTvResult> page(int number, {bool fresh = false});

  /// The newest copy already held for [number] (in memory or saved on disk),
  /// however old, or null. Quick: it never asks the site, so a viewer can show
  /// it while [page] reads the current one.
  Future<TextTvShown?> cached(int number);

  /// Reads [number] ahead of being asked for, so the page is at hand when it
  /// is. Does nothing for a page already held fresh. Never throws and says
  /// nothing: a read-ahead that fails is just a page that is read when asked
  /// for.
  Future<void> prefetch(int number);

  /// One of the site's lists: the latest changed news or sport pages, or the
  /// most read. Kept a minute (the lists change by the minute and the site
  /// is not asked more often); an older copy is given when the site cannot be
  /// reached; null when there is no list to give at all. Never throws.
  Future<List<FeedItem>?> feed(FeedKind kind);

  /// The pages held (in memory or saved on disk) with every word of [query]
  /// on a line, best first (see `searchPages`). Never asks the site: it only
  /// finds what has been read.
  Future<List<SearchHit>> search(String query);
}
