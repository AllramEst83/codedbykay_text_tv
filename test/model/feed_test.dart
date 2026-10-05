import 'dart:convert';

import 'package:codedbykay_text_tv/model/feed.dart';
import 'package:flutter_test/flutter_test.dart';

String _list(List<Map<String, Object?>> pages) =>
    jsonEncode(<String, Object?>{'ok': true, 'pages': pages});

Map<String, Object?> _entry(
  Object? page,
  Object? title, [
  Object? time = '12:06',
]) => <String, Object?>{
  'page_num': page,
  'title': title,
  'date_added_time': time,
  'page_content': 'a whole page, which a list line does not need',
};

void main() {
  group('parseFeed', () {
    test('reads the lines: page, title and time', () {
      final List<FeedItem>? items = parseFeed(
        _list(<Map<String, Object?>>[
          _entry('138', 'Skolor stänger efter protester'),
          _entry('106', 'Trio får Nobelpriset', '11:56'),
        ]),
      );

      expect(items, const <FeedItem>[
        FeedItem(138, 'Skolor stänger efter protester', '12:06'),
        FeedItem(106, 'Trio får Nobelpriset', '11:56'),
      ]);
    });

    test('a list with no lines is an empty list, not a failure', () {
      expect(parseFeed(_list(<Map<String, Object?>>[])), isEmpty);
    });

    test('an answer that is not a list is null', () {
      for (final String body in <String>[
        '',
        'nonsense',
        '[]',
        '{}',
        '{"ok": true}',
        '{"pages": 3}',
      ]) {
        expect(parseFeed(body), isNull, reason: body);
      }
    });

    test('a line that is not a page of ours, or has no title, is dropped', () {
      final List<FeedItem>? items = parseFeed(
        _list(<Map<String, Object?>>[
          _entry('99', 'Fel sida'),
          _entry('900', 'Fel sida'),
          _entry('abc', 'Fel sida'),
          _entry('150', ''),
          _entry('151', '   '),
          _entry('152', null),
          _entry('300', 'Sport'),
        ]),
      );

      expect(items, const <FeedItem>[FeedItem(300, 'Sport', '12:06')]);
    });

    test('a line that is not even a map is skipped', () {
      final String body = jsonEncode(<String, Object?>{
        'pages': <Object?>['x', 3, null, _entry('300', 'Sport')],
      });

      expect(parseFeed(body), hasLength(1));
    });

    test('a page is listed once, the first line counting', () {
      final List<FeedItem>? items = parseFeed(
        _list(<Map<String, Object?>>[
          _entry('300', 'Nyast'),
          _entry('300', 'Äldre'),
        ]),
      );

      expect(items!.single.title, 'Nyast');
    });

    test('the title\'s spacing is tidied', () {
      final List<FeedItem>? items = parseFeed(
        _list(<Map<String, Object?>>[_entry('300', '  Mycket    luft\n här ')]),
      );

      expect(items!.single.title, 'Mycket luft här');
    });

    test('a time that is not a clock time is none', () {
      final List<FeedItem>? items = parseFeed(
        _list(<Map<String, Object?>>[
          _entry('300', 'A', 'igår'),
          _entry('301', 'B', null),
          _entry('302', 'C', '9:05'),
        ]),
      );

      expect(items!.map((FeedItem i) => i.time), <String?>[null, null, '9:05']);
    });

    test('no more than the most lines', () {
      final List<FeedItem>? items = parseFeed(
        _list(<Map<String, Object?>>[
          for (int i = 0; i < 100; i++) _entry('${100 + i}', 'Rubrik $i'),
        ]),
      );

      expect(items, hasLength(maxFeedItems));
    });
  });

  test('items are equal when all of them is', () {
    expect(const FeedItem(100, 'A', '1:00'), const FeedItem(100, 'A', '1:00'));
    expect(
      const FeedItem(100, 'A').hashCode,
      const FeedItem(100, 'A').hashCode,
    );
    expect(const FeedItem(100, 'A'), isNot(const FeedItem(100, 'B')));
  });
}
