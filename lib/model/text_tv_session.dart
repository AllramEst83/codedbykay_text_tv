import 'dart:convert';

import 'package:codedbykay_text_tv/model/text_tv_page.dart';

/// Where the reader was: what a cold start comes back to. Tolerant on the way
/// in, because it is read from disk: anything unreadable or out of range falls
/// back to the front page rather than failing.
class TextTvSession {
  const TextTvSession({
    this.page = textTvFirstPage,
    this.part = 0,
    this.history = const <int>[],
  });

  /// The most pages of history kept, oldest dropped first.
  static const int maxHistory = 50;

  final int page;

  /// The sub-page on [page] (0-based).
  final int part;

  /// Pages left behind, most recent last: what back returns to.
  final List<int> history;

  static bool _isPage(Object? value) =>
      value is int && value >= textTvFirstPage && value <= textTvLastPage;

  /// Reads what [encode] wrote. Null, malformed or wrong-shaped input gives
  /// the default session; a bad field is replaced, the rest is kept.
  factory TextTvSession.decode(String? source) {
    if (source == null) return const TextTvSession();
    final Object? json;
    try {
      json = jsonDecode(source);
    } on FormatException {
      return const TextTvSession();
    }
    if (json is! Map<String, Object?>) return const TextTvSession();
    final Object? page = json['page'];
    if (!_isPage(page)) return const TextTvSession();
    final Object? part = json['part'];
    final Object? history = json['history'];
    return TextTvSession(
      page: page! as int,
      part: part is int && part >= 0 ? part : 0,
      history: history is List
          ? <int>[
              for (final Object? n in history)
                if (_isPage(n)) n! as int,
            ].takeLast(maxHistory)
          : const <int>[],
    );
  }

  String encode() => jsonEncode(<String, Object?>{
    'page': page,
    'part': part,
    'history': history.takeLast(maxHistory),
  });

  @override
  bool operator ==(Object other) =>
      other is TextTvSession &&
      other.page == page &&
      other.part == part &&
      other.history.length == history.length &&
      Iterable<int>.generate(history.length)
          .every((int i) => other.history[i] == history[i]);

  @override
  int get hashCode => Object.hash(page, part, Object.hashAll(history));
}

extension on List<int> {
  List<int> takeLast(int count) =>
      length <= count ? this : sublist(length - count);
}
