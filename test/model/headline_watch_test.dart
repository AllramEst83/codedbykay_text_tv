import 'package:codedbykay_text_tv/model/headline_watch.dart';
import 'package:codedbykay_text_tv/model/text_tv_page.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('breakingHeadline', () {
    const List<String> before = <String>['Ett', 'Två', 'Tre'];

    test('a new top headline is news', () {
      expect(breakingHeadline(before, <String>['Nytt', 'Ett', 'Två']), 'Nytt');
    });

    test('the same top headline is not', () {
      expect(breakingHeadline(before, <String>['Ett', 'Två', 'Tre']), isNull);
    });

    test('a headline that only moved down or came back is not news', () {
      expect(breakingHeadline(before, <String>['Två', 'Ett', 'Tre']), isNull);
    });

    test('a change further down is not news', () {
      expect(
        breakingHeadline(before, <String>['Ett', 'Ny rad', 'Tre']),
        isNull,
      );
    });

    test('the first look, with nothing to compare with, is not news', () {
      expect(breakingHeadline(<String>[], <String>['Nytt']), isNull);
    });

    test('a page with no headlines is not news', () {
      expect(breakingHeadline(before, <String>[]), isNull);
    });
  });

  group('watchedHeadlines', () {
    test('are the headlines with their spacing collapsed', () {
      const TextTvPage page = TextTvPage(
        number: 100,
        parts: <List<String>>[
          <String>['100 SVT Text', '  Hej    världen   105', '', '105'],
        ],
      );

      expect(watchedHeadlines(page), <String>['Hej världen']);
    });
  });

  group('WatchState', () {
    test('survives a round trip', () {
      const WatchState s = WatchState(page: 300, headlines: <String>['A', 'B']);

      expect(WatchState.decode(s.encode()), s);
      expect(WatchState.decode(s.encode()).hashCode, s.hashCode);
    });

    test('nothing saved or nonsense is nothing seen', () {
      for (final String? source in <String?>[
        null,
        '',
        'garbage',
        '[]',
        '{}',
        '{"page": "x", "headlines": []}',
        '{"page": 100, "headlines": 3}',
      ]) {
        expect(
          WatchState.decode(source),
          const WatchState(),
          reason: '$source',
        );
      }
    });

    test('a bad entry among the headlines is dropped, not the rest', () {
      final WatchState s = WatchState.decode(
        '{"page": 100, "headlines": ["A", 3, null, "B"]}',
      );

      expect(s.headlines, <String>['A', 'B']);
    });

    test('is only for the page it was made for', () {
      const WatchState s = WatchState(page: 100, headlines: <String>['A']);

      expect(s.forPage(100), <String>['A']);
      expect(s.forPage(300), isEmpty);
    });
  });
}
