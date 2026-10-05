import 'dart:convert';

import 'package:codedbykay_text_tv/model/text_tv_page.dart';

/// The lists texttv.nu keeps beside the pages themselves.
enum FeedKind {
  /// The news pages changed most lately.
  latestNews,

  /// The sport pages changed most lately.
  latestSport,

  /// The pages read most today.
  mostRead,
}

/// One line of such a list: a page, what it says at the top, and when it was
/// changed (`12:06`, when the list says).
class FeedItem {
  const FeedItem(this.page, this.title, [this.time]);

  final int page;
  final String title;
  final String? time;

  @override
  bool operator ==(Object other) =>
      other is FeedItem &&
      other.page == page &&
      other.title == title &&
      other.time == time;

  @override
  int get hashCode => Object.hash(page, title, time);
}

/// The most lines of a list kept: it is for picking from, not reading.
const int maxFeedItems = 25;

final RegExp _clock = RegExp(r'^\d{1,2}:\d{2}$');

/// The lines of a list answer (`{"ok": true, "pages": [...]}`), read
/// tolerantly: a line that is not a page of ours, or has no title, is dropped
/// (never the rest), and a page is listed once. Null when the answer is not
/// a list at all.
List<FeedItem>? parseFeed(String body) {
  final Object? json;
  try {
    json = jsonDecode(body);
  } on FormatException {
    return null;
  }
  if (json is! Map || json['pages'] is! List) return null;
  final List<FeedItem> items = <FeedItem>[];
  final Set<int> seen = <int>{};
  for (final Object? entry in json['pages'] as List) {
    if (entry is! Map) continue;
    final int? page = int.tryParse('${entry['page_num']}');
    final String title = '${entry['title'] ?? ''}'.trim().replaceAll(
      RegExp(r'\s+'),
      ' ',
    );
    if (page == null ||
        page < textTvFirstPage ||
        page > textTvLastPage ||
        title.isEmpty ||
        !seen.add(page)) {
      continue;
    }
    final String time = '${entry['date_added_time'] ?? ''}'.trim();
    items.add(FeedItem(page, title, _clock.hasMatch(time) ? time : null));
    if (items.length >= maxFeedItems) break;
  }
  return items;
}
