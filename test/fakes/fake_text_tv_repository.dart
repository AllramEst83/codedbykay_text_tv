import 'package:codedbykay_text_tv/model/feed.dart';
import 'package:codedbykay_text_tv/model/page_search.dart';
import 'package:codedbykay_text_tv/model/text_tv_page.dart';
import 'package:codedbykay_text_tv/services/text_tv_repository.dart';

/// Serves pages from [pages] (anything else is [TextTvNotBroadcast]), or
/// [failure] for every request while it is set, and records what was asked.
class FakeTextTvRepository implements TextTvRepository {
  FakeTextTvRepository([
    Map<int, TextTvPage>? pages,
    DateTime Function()? clock,
  ]) : pages = pages ?? <int, TextTvPage>{},
       clock = clock ?? DateTime.now;

  /// What time a page read now is said to have been read.
  final DateTime Function() clock;

  final Map<int, TextTvPage> pages;
  TextTvResult? failure;

  /// Pages [cached] has at once, as a saved copy would; empty by default.
  final Map<int, TextTvPage> cachedCopies = <int, TextTvPage>{};

  /// Every page read ahead, in order.
  final List<int> prefetched = <int>[];

  /// Every `(number, fresh)` asked for, in order.
  final List<(int, bool)> requests = <(int, bool)>[];

  @override
  Future<TextTvResult> page(int number, {bool fresh = false}) async {
    requests.add((number, fresh));
    final TextTvResult? failed = failure;
    if (failed != null) return failed;
    final TextTvPage? page = pages[number];
    return page == null
        ? TextTvNotBroadcast(number)
        : TextTvShown(page, readAt: clock());
  }

  @override
  Future<TextTvShown?> cached(int number) async {
    final TextTvPage? page = cachedCopies[number];
    return page == null ? null : TextTvShown(page);
  }

  @override
  Future<void> prefetch(int number) async {
    prefetched.add(number);
  }

  /// What [feed] gives for each kind; a kind not here has no list.
  final Map<FeedKind, List<FeedItem>> feeds = <FeedKind, List<FeedItem>>{};

  /// Every kind of list asked for, in order.
  final List<FeedKind> feedRequests = <FeedKind>[];

  @override
  Future<List<FeedItem>?> feed(FeedKind kind) async {
    feedRequests.add(kind);
    return feeds[kind];
  }

  /// Every query searched for, in order.
  final List<String> searches = <String>[];

  /// Pages [search] looks in; the pages served by default.
  List<TextTvPage>? searchable;

  @override
  Future<List<SearchHit>> search(String query) async {
    searches.add(query);
    return searchPages(searchable ?? pages.values, query);
  }
}
