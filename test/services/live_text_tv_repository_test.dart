import 'dart:convert';

import 'package:codedbykay_text_tv/model/network_failure.dart';
import 'package:codedbykay_text_tv/model/text_tv_page.dart';
import 'package:codedbykay_text_tv/services/live_text_tv_repository.dart';
import 'package:codedbykay_text_tv/services/network_exception.dart';
import 'package:codedbykay_text_tv/services/page_disk_cache.dart';
import 'package:codedbykay_text_tv/services/text_tv.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fakes/fake_http_fetcher.dart';

String _page(int number, {String line = 'Hello'}) => jsonEncode(<Object>[
  <String, Object>{
    'num': '$number',
    'content_plain': <String>[line],
    'next_page': '${number + 1}',
    'prev_page': '${number - 1}',
  },
]);

void main() {
  late FakeHttpFetcher fetcher;
  late DateTime now;
  late LiveTextTvRepository repository;
  setUp(() {
    fetcher = FakeHttpFetcher()
      ..route('/api/get/', (Uri url) {
        final int number = int.parse(url.pathSegments.last);
        return _page(number);
      });
    now = DateTime(2026, 9, 28, 10);
    repository = LiveTextTvRepository(
      textTv: TextTv(fetcher: fetcher),
      maxAge: const Duration(minutes: 5),
      capacity: 3,
      clock: () => now,
      retryDelay: Duration.zero,
    );
  });

  test('reads a page from the site', () async {
    final TextTvResult result = await repository.page(130);

    expect(result, isA<TextTvShown>());
    expect((result as TextTvShown).page.number, 130);
    expect(fetcher.requests, hasLength(1));
  });

  test('a page read a moment ago is not read again', () async {
    await repository.page(130);
    now = now.add(const Duration(minutes: 4));

    await repository.page(130);

    expect(fetcher.requests, hasLength(1));
  });

  test('past its age it is read again', () async {
    await repository.page(130);
    now = now.add(const Duration(minutes: 5));

    await repository.page(130);

    expect(fetcher.requests, hasLength(2));
  });

  test('fresh always asks the site', () async {
    await repository.page(130);

    await repository.page(130, fresh: true);

    expect(fetcher.requests, hasLength(2));
  });

  test(
    'a page that is not in broadcast says so, and is asked for again',
    () async {
      fetcher.route('/api/get/999', '[]');

      final TextTvResult first = await repository.page(999);
      await repository.page(999);

      expect(first, isA<TextTvNotBroadcast>());
      expect((first as TextTvNotBroadcast).number, 999);
      expect(fetcher.requests, hasLength(2));
    },
  );

  test('a failure says why, and is not kept', () async {
    fetcher.route(
      '/api/get/500',
      const NetworkException('x', failure: NetworkFailure.other),
    );

    final TextTvResult first = await repository.page(500);
    await repository.page(500);

    expect((first as TextTvFailed).failure, NetworkFailure.other);
    expect(fetcher.requests, hasLength(2));
  });

  group('a failure that may pass is tried once more', () {
    test('and the second try can save the day', () async {
      int calls = 0;
      fetcher.route('/api/get/500', (Uri url) {
        calls++;
        return calls == 1
            ? const NetworkException('x', failure: NetworkFailure.timeout)
            : _page(500);
      });

      final TextTvResult result = await repository.page(500);

      expect(result, isA<TextTvShown>());
      expect(fetcher.requests, hasLength(2));
    });

    test('and when it fails again, the failure is told', () async {
      fetcher.route(
        '/api/get/500',
        const NetworkException('x', failure: NetworkFailure.server),
      );

      final TextTvResult result = await repository.page(500);

      expect((result as TextTvFailed).failure, NetworkFailure.server);
      expect(fetcher.requests, hasLength(2));
    });

    test('waits before it does', () async {
      final LiveTextTvRepository slow = LiveTextTvRepository(
        textTv: TextTv(fetcher: fetcher),
        retryDelay: const Duration(seconds: 1),
      );
      fetcher.route(
        '/api/get/500',
        const NetworkException('x', failure: NetworkFailure.offline),
      );

      final Stopwatch watch = Stopwatch()..start();
      await slow.page(500);

      expect(watch.elapsedMilliseconds, greaterThanOrEqualTo(900));
    });

    test('a site that has changed is not asked again', () async {
      fetcher.route('/api/get/500', 'not json');

      final TextTvResult result = await repository.page(500);

      expect((result as TextTvFailed).failure, NetworkFailure.changed);
      expect(fetcher.requests, hasLength(1));
    });

    test('a read-ahead gives up at once and says nothing', () async {
      fetcher.route(
        '/api/get/500',
        const NetworkException('x', failure: NetworkFailure.offline),
      );

      await repository.prefetch(500);

      expect(fetcher.requests, hasLength(1));
    });
  });

  test('keeps only the most recently read pages', () async {
    await repository.page(101);
    await repository.page(102);
    await repository.page(103);
    await repository.page(104); // pushes 101 out

    await repository.page(104);
    await repository.page(102);
    expect(fetcher.requests, hasLength(4));

    await repository.page(101);
    expect(fetcher.requests, hasLength(5));
  });

  group('reading ahead', () {
    test('reads the page, so a later request needs no network', () async {
      await repository.prefetch(140);
      expect(fetcher.requests, hasLength(1));

      final TextTvResult result = await repository.page(140);

      expect(result, isA<TextTvShown>());
      expect(fetcher.requests, hasLength(1), reason: 'answered from memory');
    });

    test('does nothing for a page already held fresh', () async {
      await repository.page(140);
      fetcher.requests.clear();

      await repository.prefetch(140);

      expect(fetcher.requests, isEmpty);
    });

    test('reads again a page that has gone stale', () async {
      await repository.page(140);
      now = now.add(const Duration(minutes: 6));
      fetcher.requests.clear();

      await repository.prefetch(140);

      expect(fetcher.requests, hasLength(1));
    });

    test('never throws when the site cannot be reached', () async {
      fetcher.route('/api/get/', const NetworkException('no signal'));

      await expectLater(repository.prefetch(140), completes);
    });

    test(
      'a failed read-ahead leaves the page to be read when asked for',
      () async {
        fetcher.route('/api/get/', const NetworkException('no signal'));
        await repository.prefetch(140);
        fetcher.route('/api/get/', (Uri url) => _page(140));

        final TextTvResult result = await repository.page(140);

        expect(result, isA<TextTvShown>());
      },
    );

    test('a page not in broadcast is no trouble', () async {
      fetcher.route('/api/get/', '[]');

      await expectLater(repository.prefetch(140), completes);
      expect(await repository.page(140), isA<TextTvNotBroadcast>());
    });
  });

  group('with a disk cache', () {
    late _MemoryDisk disk;
    late LiveTextTvRepository saving;
    setUp(() {
      disk = _MemoryDisk();
      saving = LiveTextTvRepository(
        textTv: TextTv(fetcher: fetcher),
        disk: disk,
        clock: () => now,
      );
    });

    test('a page read is saved as the site sent it, with the time', () async {
      await saving.page(130);

      expect(disk.saved[130]?.body, _page(130));
      expect(disk.saved[130]?.savedAt, now);
    });

    test('when the site cannot be reached the saved copy is shown', () async {
      await saving.page(130);
      final DateTime savedAt = now;
      now = now.add(const Duration(hours: 3));
      fetcher.route('/api/get/', const NetworkException('no signal'));

      final TextTvResult result = await saving.page(130, fresh: true);

      expect(result, isA<TextTvShown>());
      final TextTvShown shown = result as TextTvShown;
      expect(shown.page.number, 130);
      expect(shown.cachedAt, savedAt);
    });

    test('a saved copy from an earlier run is shown too', () async {
      disk.saved[130] = SavedPage(
        _page(130, line: 'Yesterday'),
        DateTime(2026, 9, 27),
      );
      fetcher.route('/api/get/', const NetworkException('no signal'));

      final TextTvShown shown = await saving.page(130) as TextTvShown;

      expect(shown.page.parts.first, <String>['Yesterday']);
      expect(shown.cachedAt, DateTime(2026, 9, 27));
    });

    test('with no saved copy a failure still says why', () async {
      fetcher.route('/api/get/', const NetworkException('no signal'));

      final TextTvResult result = await saving.page(130);

      expect(result, isA<TextTvFailed>());
      expect((result as TextTvFailed).failure, NetworkFailure.other);
    });

    test('a saved copy that cannot be read is ignored', () async {
      disk.saved[130] = SavedPage('not json', now);
      fetcher.route('/api/get/', const NetworkException('no signal'));

      expect(await saving.page(130), isA<TextTvFailed>());
    });

    test('a page that is not in broadcast is forgotten from disk', () async {
      await saving.page(130);
      fetcher.route('/api/get/', '[]');

      final TextTvResult result = await saving.page(130, fresh: true);

      expect(result, isA<TextTvNotBroadcast>());
      expect(disk.saved, isEmpty);
    });

    test('a page read again after a failure is a plain page again', () async {
      await saving.page(130);
      fetcher.route('/api/get/', const NetworkException('no signal'));
      await saving.page(130, fresh: true);
      fetcher.route('/api/get/', (Uri url) => _page(130, line: 'Back'));

      final TextTvShown shown =
          await saving.page(130, fresh: true) as TextTvShown;

      expect(shown.cachedAt, isNull);
      expect(shown.page.parts.first, <String>['Back']);
    });

    test('cached gives the copy held in memory, without asking', () async {
      await saving.page(130);
      fetcher.requests.clear();

      final TextTvShown? held = await saving.cached(130);

      expect(held?.page.number, 130);
      expect(held?.cachedAt, isNull);
      expect(fetcher.requests, isEmpty);
    });

    test('cached falls back to the disk, and to nothing', () async {
      disk.saved[130] = SavedPage(_page(130, line: 'On disk'), now);

      final TextTvShown? held = await saving.cached(130);

      expect(held?.page.parts.first, <String>['On disk']);
      expect(held?.cachedAt, isNull, reason: 'not marked as offline');
      expect(await saving.cached(131), isNull);
      expect(fetcher.requests, isEmpty);
    });

    test('without a disk cache a failure is a failure', () async {
      await repository.page(130);
      fetcher.route('/api/get/', const NetworkException('no signal'));

      expect(await repository.page(130, fresh: true), isA<TextTvFailed>());
      expect(await repository.cached(131), isNull);
    });
  });
}

class _MemoryDisk implements PageDiskCache {
  final Map<int, SavedPage> saved = <int, SavedPage>{};

  @override
  Future<SavedPage?> read(int number) async => saved[number];

  @override
  Future<void> write(int number, String body, DateTime at) async =>
      saved[number] = SavedPage(body, at);

  @override
  Future<void> remove(int number) async => saved.remove(number);
}
