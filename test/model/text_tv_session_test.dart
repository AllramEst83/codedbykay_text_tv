import 'package:codedbykay_text_tv/model/text_tv_session.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('TextTvSession', () {
    test('the default is the front page, first part, no history', () {
      const TextTvSession session = TextTvSession();

      expect(session.page, 100);
      expect(session.part, 0);
      expect(session.history, isEmpty);
    });

    test('survives a round trip', () {
      const TextTvSession session = TextTvSession(
        page: 377,
        part: 2,
        history: <int>[100, 300],
      );

      expect(TextTvSession.decode(session.encode()), session);
    });

    test('nothing saved gives the default', () {
      expect(TextTvSession.decode(null), const TextTvSession());
    });

    test('unreadable input gives the default', () {
      for (final String bad in <String>['', 'not json', '[]', '42', '{']) {
        expect(TextTvSession.decode(bad), const TextTvSession(), reason: bad);
      }
    });

    test('a page outside 100 to 899 gives the default', () {
      for (final String page in <String>['99', '900', '"377"', 'null']) {
        expect(
          TextTvSession.decode('{"page": $page, "part": 1}'),
          const TextTvSession(),
          reason: page,
        );
      }
    });

    test('a bad part becomes 0 and keeps the page', () {
      expect(
        TextTvSession.decode('{"page": 300, "part": -1}'),
        const TextTvSession(page: 300),
      );
      expect(
        TextTvSession.decode('{"page": 300, "part": "x"}'),
        const TextTvSession(page: 300),
      );
    });

    test('bad history entries are dropped, the good ones kept', () {
      expect(
        TextTvSession.decode(
          '{"page": 300, "history": [100, 5, "x", 900, 400, null]}',
        ).history,
        <int>[100, 400],
      );
      expect(
        TextTvSession.decode('{"page": 300, "history": 7}').history,
        isEmpty,
      );
    });

    test('keeps only the most recent history when decoding and encoding', () {
      final List<int> long = <int>[
        for (int i = 0; i < TextTvSession.maxHistory + 5; i++) 100 + i,
      ];
      final TextTvSession session = TextTvSession(page: 300, history: long);

      final TextTvSession decoded = TextTvSession.decode(session.encode());

      expect(decoded.history, hasLength(TextTvSession.maxHistory));
      expect(decoded.history.last, long.last);
      expect(decoded.history.first, long[5]);
    });
  });
}
