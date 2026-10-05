import 'dart:convert';

import 'package:codedbykay_text_tv/model/background_memory.dart';
import 'package:codedbykay_text_tv/model/background_settings.dart';
import 'package:codedbykay_text_tv/model/headline_watch.dart';
import 'package:codedbykay_text_tv/services/background_refresher.dart';
import 'package:codedbykay_text_tv/services/background_settings_store.dart';
import 'package:codedbykay_text_tv/services/network_exception.dart';
import 'package:codedbykay_text_tv/services/text_tv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../fakes/fake_background.dart';
import '../fakes/fake_http_fetcher.dart';

String _page(int number, List<String> lines, {int? changed}) =>
    jsonEncode(<Object>[
      <String, Object>{
        'num': '$number',
        'content_plain': <String>['$number SVT Text\n${lines.join('\n')}'],
        'next_page': '${number + 1}',
        'prev_page': '${number - 1}',
        'date_updated_unix': ?changed,
      },
    ]);

class _MemoryStore implements BackgroundMemoryStore {
  BackgroundMemory memory = const BackgroundMemory();

  @override
  Future<BackgroundMemory> load() async => memory;

  @override
  Future<void> save(BackgroundMemory m) async => memory = m;
}

String _says(bool available) =>
    jsonEncode(<String, Object>{'is_ok': true, 'update_available': available});

void main() {
  late FakeHttpFetcher fetcher;
  late FakeWidgetPlatform widget;
  late FakeAlertPlatform alerts;
  late FakeWatchStateStore watch;
  late FakeBackgroundSettingsStore settings;
  late _MemoryStore memory;
  late BackgroundRefresher refresher;
  late List<String> news;
  late bool changed;
  setUp(() {
    news = <String>['Gammal rubrik', 'Annan rubrik'];
    changed = true;
    fetcher = FakeHttpFetcher()
      ..route('/api/get/', (Uri u) {
        return _page(int.parse(u.pathSegments.last), news, changed: 1791000000);
      })
      ..route('/api/updated/', (Uri u) => _says(changed));
    widget = FakeWidgetPlatform();
    alerts = FakeAlertPlatform();
    watch = FakeWatchStateStore();
    settings = FakeBackgroundSettingsStore();
    memory = _MemoryStore();
    refresher = BackgroundRefresher(
      textTv: TextTv(fetcher: fetcher),
      settings: settings,
      widget: widget,
      alerts: alerts,
      watch: watch,
      memory: memory,
      pause: Duration.zero,
      clock: () => DateTime.fromMillisecondsSinceEpoch(1791100000 * 1000),
    );
  });

  List<String> asked() => fetcher.requests
      .map((Uri u) => u.pathSegments.skip(1).join('/'))
      .toList();

  group('a run asks first, and reads only what changed', () {
    test(
      'the first run has nothing to compare with and reads the page',
      () async {
        await refresher.run();

        expect(asked(), <String>['get/100']);
        expect(widget.published, hasLength(1));
        expect(memory.memory.updated[100], 1791000000);
      },
    );

    test('the next run asks with the time the site gave', () async {
      await refresher.run();
      fetcher.requests.clear();
      changed = false;

      await refresher.run();

      expect(asked(), <String>['updated/100/1791000000']);
    });

    test(
      'a page that did not change is not read, and the widget is left',
      () async {
        await refresher.run();
        fetcher.requests.clear();
        changed = false;

        await refresher.run();

        expect(asked(), hasLength(1), reason: 'only the question');
        expect(widget.published, hasLength(1));
      },
    );

    test('a page that changed is read and given to the widget', () async {
      await refresher.run();
      fetcher.requests.clear();
      news = <String>['Ny rubrik'];

      await refresher.run();

      expect(asked(), <String>['updated/100/1791000000', 'get/100']);
      expect(widget.published.last.lines, <String>['Ny rubrik']);
    });

    test('the question itself is small: one request, the app named', () async {
      await refresher.run();
      fetcher.requests.clear();
      changed = false;

      await refresher.run();

      expect(fetcher.requests.single.queryParameters['app'], 'texttv_android');
    });

    test(
      'a page the site gave no time for is remembered by our own clock',
      () async {
        fetcher.route('/api/get/', (Uri u) => _page(100, news));

        await refresher.run();

        expect(memory.memory.updated[100], 1791100000);
      },
    );

    test(
      'a question that cannot be answered reads nothing and changes nothing',
      () async {
        await refresher.run();
        fetcher.requests.clear();
        fetcher.route('/api/updated/', const NetworkException('down'));

        await refresher.run();

        expect(asked(), <String>['updated/100/1791000000']);
        expect(widget.published, hasLength(1));
      },
    );

    test('an answer that makes no sense reads nothing either', () async {
      await refresher.run();
      fetcher.requests.clear();
      fetcher.route('/api/updated/', 'nonsense');

      await expectLater(refresher.run(), completes);

      expect(asked(), <String>['updated/100/1791000000']);
    });
  });

  group('but reads at once when the widget needs it', () {
    test('a widget that has been given nothing yet', () async {
      memory.memory = const BackgroundMemory(
        updated: <int, int>{100: 1791000000},
      );
      changed = false;

      await refresher.run();

      expect(asked(), <String>['get/100']);
      expect(widget.published, hasLength(1));
    });

    test('a widget whose page was changed in settings', () async {
      await refresher.run();
      fetcher.requests.clear();
      changed = false;
      settings.settings = const BackgroundSettings(widgetPage: 300);

      await refresher.run();

      expect(asked(), <String>['get/300']);
      expect(memory.memory.widgetShown, 300);
    });
  });

  group('and for alerts', () {
    setUp(() {
      widget.installed = false;
      settings.settings = const BackgroundSettings(alerts: true);
    });

    test('a page changed means a new top headline is announced', () async {
      await refresher.run();
      fetcher.requests.clear();
      news = <String>['Ny huvudrubrik', 'Gammal rubrik'];

      await refresher.run();

      expect(alerts.shown, <(int, String)>[(100, 'Ny huvudrubrik')]);
    });

    test(
      'an unchanged page announces nothing and costs one question',
      () async {
        await refresher.run();
        fetcher.requests.clear();
        changed = false;

        await refresher.run();

        expect(alerts.shown, isEmpty);
        expect(asked(), <String>['updated/100/1791000000']);
      },
    );

    test(
      'alerts that have seen nothing read the page whatever the site says',
      () async {
        memory.memory = const BackgroundMemory(
          updated: <int, int>{100: 1791000000},
        );
        changed = false;

        await refresher.run();

        expect(asked(), <String>['get/100']);
        expect(watch.state.page, 100);
      },
    );

    test('with widget and alerts on one page, one read serves both', () async {
      widget.installed = true;
      await refresher.run();

      expect(asked(), <String>['get/100']);
      expect(widget.published, hasLength(1));
      expect(watch.state.page, 100);
    });

    test(
      'with widget and alerts on one page and no change, one question',
      () async {
        widget.installed = true;
        await refresher.run();
        fetcher.requests.clear();
        changed = false;

        await refresher.run();

        expect(asked(), <String>['updated/100/1791000000']);
      },
    );
  });

  group('without a memory every run reads every page', () {
    test('as before', () async {
      final BackgroundRefresher plain = BackgroundRefresher(
        textTv: TextTv(fetcher: fetcher),
        settings: settings,
        widget: widget,
        pause: Duration.zero,
      );

      await plain.run();
      await plain.run();

      expect(asked(), <String>['get/100', 'get/100']);
    });
  });

  group('TextTv.hasUpdate', () {
    test('says whether the site has something newer', () async {
      final TextTv tv = TextTv(fetcher: fetcher);

      changed = true;
      expect(await tv.hasUpdate(300, 5), isTrue);
      changed = false;
      expect(await tv.hasUpdate(300, 5), isFalse);
    });

    test('asks for the page and the time in the address', () async {
      await TextTv(fetcher: fetcher).hasUpdate(377, 1791000000);

      expect(fetcher.requests.single.path, '/api/updated/377/1791000000');
    });

    test(
      'an answer that is not the question\'s is the site having changed',
      () async {
        for (final String body in <String>[
          'nonsense',
          '[]',
          '{}',
          '{"update_available": "yes"}',
        ]) {
          fetcher.route('/api/updated/', body);
          await expectLater(
            TextTv(fetcher: fetcher).hasUpdate(100, 1),
            throwsA(isA<NetworkException>()),
            reason: body,
          );
        }
      },
    );

    test('a site that cannot be reached throws', () async {
      fetcher.route('/api/updated/', const NetworkException('down'));

      await expectLater(
        TextTv(fetcher: fetcher).hasUpdate(100, 1),
        throwsA(isA<NetworkException>()),
      );
    });
  });

  group('BackgroundMemory', () {
    test('survives a round trip', () {
      const BackgroundMemory m = BackgroundMemory(
        updated: <int, int>{100: 5, 300: 9},
        widgetShown: 300,
      );
      final BackgroundMemory back = BackgroundMemory.decode(m.encode());

      expect(back.updated, <int, int>{100: 5, 300: 9});
      expect(back.widgetShown, 300);
    });

    test('nothing saved or nonsense remembers nothing', () {
      for (final String? source in <String?>[null, '', 'x', '[]', '{}']) {
        final BackgroundMemory m = BackgroundMemory.decode(source);
        expect(m.updated, isEmpty, reason: '$source');
        expect(m.widgetShown, isNull);
      }
    });

    test('a bad entry is dropped, not the rest', () {
      final BackgroundMemory m = BackgroundMemory.decode(
        '{"updated": {"100": 5, "5": 7, "abc": 1, "300": -1, "400": "x", "500": 9},'
        ' "widgetShown": 99}',
      );

      expect(m.updated, <int, int>{100: 5, 500: 9});
      expect(m.widgetShown, isNull);
    });

    test('keeps at most a few pages, the longest ago read going first', () {
      BackgroundMemory m = const BackgroundMemory();
      for (int i = 0; i < BackgroundMemory.maxPages + 3; i++) {
        m = m.withUpdated(100 + i, 10 + i);
      }

      expect(m.updated, hasLength(BackgroundMemory.maxPages));
      expect(m.updated.containsKey(100), isFalse);
      expect(
        m.updated.containsKey(100 + BackgroundMemory.maxPages + 2),
        isTrue,
      );
    });

    test('a page read again moves to the end', () {
      final BackgroundMemory m = const BackgroundMemory()
          .withUpdated(100, 1)
          .withUpdated(300, 2)
          .withUpdated(100, 3);

      expect(m.updated.keys.toList(), <int>[300, 100]);
      expect(m.updated[100], 3);
    });
  });

  group('PrefsBackgroundMemoryStore', () {
    setUp(() => SharedPreferences.setMockInitialValues(<String, Object>{}));

    test('a first run remembers nothing', () async {
      expect((await PrefsBackgroundMemoryStore().load()).updated, isEmpty);
    });

    test('gives back what was saved, to a new store too', () async {
      await PrefsBackgroundMemoryStore().save(
        const BackgroundMemory(updated: <int, int>{100: 5}, widgetShown: 100),
      );

      final BackgroundMemory m = await PrefsBackgroundMemoryStore().load();
      expect(m.updated, <int, int>{100: 5});
      expect(m.widgetShown, 100);
    });

    test('a damaged value remembers nothing', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{
        PrefsBackgroundMemoryStore.key: 'garbage',
      });

      expect((await PrefsBackgroundMemoryStore().load()).updated, isEmpty);
    });
  });

  test('the watch state used above is the alerts\' own', () {
    expect(const WatchState().page, 0);
  });
}
