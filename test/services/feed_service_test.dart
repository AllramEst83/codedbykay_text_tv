import 'dart:convert';

import 'package:codedbykay_text_tv/model/feed.dart';
import 'package:codedbykay_text_tv/services/live_text_tv_repository.dart';
import 'package:codedbykay_text_tv/services/network_exception.dart';
import 'package:codedbykay_text_tv/services/text_tv.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fakes/fake_http_fetcher.dart';

String _list(String title) => jsonEncode(<String, Object?>{
  'ok': true,
  'pages': <Object?>[
    <String, Object?>{
      'page_num': '138',
      'title': title,
      'date_added_time': '12:06',
    },
  ],
});

void main() {
  late FakeHttpFetcher fetcher;
  late DateTime now;
  late LiveTextTvRepository repository;
  setUp(() {
    fetcher = FakeHttpFetcher()..route('/api/', _list('Rubrik'));
    now = DateTime(2026, 10, 5, 12);
    repository = LiveTextTvRepository(
      textTv: TextTv(fetcher: fetcher),
      clock: () => now,
    );
  });

  group('TextTv.feed', () {
    test('asks for each list at its own address, naming the app', () async {
      final TextTv tv = TextTv(fetcher: fetcher);

      await tv.feed(FeedKind.latestNews);
      await tv.feed(FeedKind.latestSport);
      await tv.feed(FeedKind.mostRead);

      expect(fetcher.requests.map((Uri u) => u.path), <String>[
        '/api/last_updated/news',
        '/api/last_updated/sport',
        '/api/most_read',
      ]);
      for (final Uri u in fetcher.requests) {
        expect(u.scheme, 'https');
        expect(u.host, 'texttv.nu');
        expect(u.queryParameters['app'], 'texttv_android');
      }
    });

    test('gives the lines', () async {
      expect(
        await TextTv(fetcher: fetcher).feed(FeedKind.mostRead),
        const <FeedItem>[FeedItem(138, 'Rubrik', '12:06')],
      );
    });

    test('an answer that is not a list is the site having changed', () async {
      fetcher.route('/api/', 'nonsense');

      await expectLater(
        TextTv(fetcher: fetcher).feed(FeedKind.mostRead),
        throwsA(
          isA<NetworkException>().having(
            (NetworkException e) => e.failure.name,
            'failure',
            'changed',
          ),
        ),
      );
    });
  });

  group('the repository', () {
    test('keeps a list for a minute, so the site is asked once', () async {
      await repository.feed(FeedKind.latestNews);
      now = now.add(const Duration(seconds: 59));
      await repository.feed(FeedKind.latestNews);

      expect(fetcher.requests, hasLength(1));
    });

    test('asks again after that', () async {
      await repository.feed(FeedKind.latestNews);
      now = now.add(const Duration(minutes: 1, seconds: 1));
      await repository.feed(FeedKind.latestNews);

      expect(fetcher.requests, hasLength(2));
    });

    test('keeps each kind of list apart', () async {
      await repository.feed(FeedKind.latestNews);
      await repository.feed(FeedKind.latestSport);

      expect(fetcher.requests, hasLength(2));
    });

    test('an old list is given when the site cannot be reached', () async {
      await repository.feed(FeedKind.mostRead);
      now = now.add(const Duration(hours: 1));
      fetcher.route('/api/', const NetworkException('down'));

      final List<FeedItem>? items = await repository.feed(FeedKind.mostRead);

      expect(items!.single.title, 'Rubrik');
    });

    test('with none to give it says so, and does not throw', () async {
      fetcher.route('/api/', const NetworkException('down'));

      expect(await repository.feed(FeedKind.mostRead), isNull);
    });

    test('a failure is asked again next time, not kept', () async {
      fetcher.route('/api/', const NetworkException('down'));
      await repository.feed(FeedKind.mostRead);
      fetcher.route('/api/', _list('Åter'));

      final List<FeedItem>? items = await repository.feed(FeedKind.mostRead);

      expect(items!.single.title, 'Åter');
    });
  });
}
