import 'dart:convert';

import 'package:codedbykay_text_tv/model/text_tv_page.dart';

/// How much the page is enlarged at each text-size step: 1 is the page fitted
/// to the screen's width; larger steps are wider than the screen and pan.
const List<double> textTvZoomSteps = <double>[1, 1.25, 1.5, 2, 3];

/// Where the reader was and how they were reading: what a cold start comes
/// back to. Tolerant on the way
/// in, because it is read from disk: anything unreadable or out of range falls
/// back to the front page rather than failing.
class TextTvSession {
  const TextTvSession({
    this.page = textTvFirstPage,
    this.part = 0,
    this.history = const <int>[],
    this.zoom = 0,
  });

  /// The most pages of history kept, oldest dropped first.
  static const int maxHistory = 50;

  final int page;

  /// The sub-page on [page] (0-based).
  final int part;

  /// Pages left behind, most recent last: what back returns to.
  final List<int> history;

  /// The text-size step, an index into [textTvZoomSteps].
  final int zoom;

  double get zoomFactor => textTvZoomSteps[zoom];

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
    final Object? zoom = json['zoom'];
    return TextTvSession(
      page: page! as int,
      part: part is int && part >= 0 ? part : 0,
      history: history is List
          ? <int>[
              for (final Object? n in history)
                if (_isPage(n)) n! as int,
            ].takeLast(maxHistory)
          : const <int>[],
      zoom: zoom is int && zoom >= 0 && zoom < textTvZoomSteps.length
          ? zoom
          : 0,
    );
  }

  String encode() => jsonEncode(<String, Object?>{
    'page': page,
    'part': part,
    'history': history.takeLast(maxHistory),
    'zoom': zoom,
  });

  @override
  bool operator ==(Object other) =>
      other is TextTvSession &&
      other.page == page &&
      other.part == part &&
      other.zoom == zoom &&
      other.history.length == history.length &&
      Iterable<int>.generate(history.length)
          .every((int i) => other.history[i] == history[i]);

  @override
  int get hashCode => Object.hash(page, part, zoom, Object.hashAll(history));
}

extension on List<int> {
  List<int> takeLast(int count) =>
      length <= count ? this : sublist(length - count);
}
