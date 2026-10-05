import 'dart:convert';

import 'package:codedbykay_text_tv/model/text_tv_page.dart';

/// What the background job remembers between runs so that a run can be cheap:
/// when each page it watches was last changed on the site (as the site's own
/// clock says), and which page the widget shows now.
class BackgroundMemory {
  const BackgroundMemory({this.updated = const <int, int>{}, this.widgetShown});

  /// Most pages remembered: the widget's and the alerts', a few at most.
  static const int maxPages = 8;

  /// Page number to the Unix time the site last changed it, as read.
  final Map<int, int> updated;

  /// The page the widget was last given, if it has been given one.
  final int? widgetShown;

  /// The same, with [page] now known to have been changed at [unix]. The
  /// oldest entries go past [maxPages] (insertion order is read order).
  BackgroundMemory withUpdated(int page, int unix) {
    final Map<int, int> next = <int, int>{...updated}
      ..remove(page)
      ..[page] = unix;
    while (next.length > maxPages) {
      next.remove(next.keys.first);
    }
    return BackgroundMemory(updated: next, widgetShown: widgetShown);
  }

  BackgroundMemory withWidgetShown(int page) =>
      BackgroundMemory(updated: updated, widgetShown: page);

  factory BackgroundMemory.decode(String? source) {
    if (source == null) return const BackgroundMemory();
    final Object? json;
    try {
      json = jsonDecode(source);
    } on FormatException {
      return const BackgroundMemory();
    }
    if (json is! Map<String, Object?>) return const BackgroundMemory();
    final Object? raw = json['updated'];
    final Map<int, int> updated = <int, int>{};
    if (raw is Map) {
      for (final MapEntry<Object?, Object?> e in raw.entries) {
        final int? page = int.tryParse('${e.key}');
        final Object? unix = e.value;
        if (page != null &&
            page >= textTvFirstPage &&
            page <= textTvLastPage &&
            unix is int &&
            unix > 0) {
          updated[page] = unix;
        }
        if (updated.length >= maxPages) break;
      }
    }
    final Object? shown = json['widgetShown'];
    return BackgroundMemory(
      updated: updated,
      widgetShown:
          shown is int && shown >= textTvFirstPage && shown <= textTvLastPage
          ? shown
          : null,
    );
  }

  String encode() => jsonEncode(<String, Object?>{
    'updated': <String, int>{
      for (final MapEntry<int, int> e in updated.entries) '${e.key}': e.value,
    },
    'widgetShown': widgetShown,
  });
}
