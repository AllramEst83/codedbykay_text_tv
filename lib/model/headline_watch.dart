import 'dart:convert';

import 'package:codedbykay_text_tv/model/text_tv_headlines.dart';
import 'package:codedbykay_text_tv/model/text_tv_page.dart';

final RegExp _spaces = RegExp(r'\s+');

/// The headlines of [page] as they are compared: spaces collapsed, so a row
/// padded differently is the same headline.
List<String> watchedHeadlines(TextTvPage page) => <String>[
  for (final String line in textTvHeadlines(page))
    line.trim().replaceAll(_spaces, ' '),
];

/// The headline that makes news of [current], or null when there is none: the
/// top headline, if it was not among [previous] (a headline that only moved
/// down, or came back, is not news). Nothing to compare with ([previous]
/// empty: the first look, or another page than last time) is no news either,
/// so turning alerts on does not announce what was already there.
String? breakingHeadline(List<String> previous, List<String> current) {
  if (previous.isEmpty || current.isEmpty) return null;
  final String top = current.first;
  return previous.contains(top) ? null : top;
}

/// What was last seen on the page the alerts watch, kept between runs.
class WatchState {
  const WatchState({this.page = 0, this.headlines = const <String>[]});

  final int page;
  final List<String> headlines;

  /// What to compare with when looking at [number]: nothing, if the state is
  /// for another page.
  List<String> forPage(int number) =>
      number == page ? headlines : const <String>[];

  factory WatchState.decode(String? source) {
    if (source == null) return const WatchState();
    final Object? json;
    try {
      json = jsonDecode(source);
    } on FormatException {
      return const WatchState();
    }
    if (json is! Map<String, Object?>) return const WatchState();
    final Object? page = json['page'];
    final Object? lines = json['headlines'];
    if (page is! int || lines is! List) return const WatchState();
    return WatchState(
      page: page,
      headlines: <String>[
        for (final Object? line in lines)
          if (line is String) line,
      ],
    );
  }

  String encode() =>
      jsonEncode(<String, Object?>{'page': page, 'headlines': headlines});

  @override
  bool operator ==(Object other) =>
      other is WatchState &&
      other.page == page &&
      other.headlines.length == headlines.length &&
      Iterable<int>.generate(headlines.length)
          .every((int i) => other.headlines[i] == headlines[i]);

  @override
  int get hashCode => Object.hash(page, Object.hashAll(headlines));
}
