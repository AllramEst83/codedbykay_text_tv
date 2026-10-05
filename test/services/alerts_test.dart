import 'dart:convert';

import 'package:codedbykay_text_tv/model/background_settings.dart';
import 'package:codedbykay_text_tv/model/headline_watch.dart';
import 'package:codedbykay_text_tv/services/background_coordinator.dart';
import 'package:codedbykay_text_tv/services/background_refresher.dart';
import 'package:codedbykay_text_tv/services/network_exception.dart';
import 'package:codedbykay_text_tv/services/text_tv.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fakes/fake_background.dart';
import '../fakes/fake_http_fetcher.dart';

String _page(int number, List<String> lines) => jsonEncode(<Object>[
  <String, Object>{
    'num': '$number',
    'content_plain': <String>['$number SVT Text\n${lines.join('\n')}'],
    'next_page': '${number + 1}',
    'prev_page': '${number - 1}',
  },
]);

void main() {
  late FakeHttpFetcher fetcher;
  late FakeWidgetPlatform widget;
  late FakeAlertPlatform alerts;
  late FakeWatchStateStore watch;
  late FakeBackgroundSettingsStore store;
  late BackgroundRefresher refresher;
  // What page 100 says now.
  late List<String> news;
  setUp(() {
    news = <String>['Gammal rubrik', 'Annan rubrik'];
    fetcher = FakeHttpFetcher()
      ..route('/api/get/', (Uri url) {
        final int n = int.parse(url.pathSegments.last);
        return _page(n, news);
      });
    widget = FakeWidgetPlatform()..installed = false;
    alerts = FakeAlertPlatform();
    watch = FakeWatchStateStore();
    store = FakeBackgroundSettingsStore(const BackgroundSettings(alerts: true));
    refresher = BackgroundRefresher(
      textTv: TextTv(fetcher: fetcher),
      settings: store,
      widget: widget,
      alerts: alerts,
      watch: watch,
      pause: Duration.zero,
    );
  });

  group('alerts', () {
    test('the first look announces nothing, and is remembered', () async {
      await refresher.run();

      expect(alerts.shown, isEmpty);
      expect(watch.state.headlines.first, 'Gammal rubrik');
      expect(watch.state.page, 100);
    });

    test('a new top headline is announced with its page', () async {
      await refresher.run();
      news = <String>['Ny huvudrubrik', 'Gammal rubrik'];

      await refresher.run();

      expect(alerts.shown, <(int, String)>[(100, 'Ny huvudrubrik')]);
    });

    test('and only once', () async {
      await refresher.run();
      news = <String>['Ny huvudrubrik', 'Gammal rubrik'];
      await refresher.run();
      await refresher.run();

      expect(alerts.shown, hasLength(1));
    });

    test('an unchanged page announces nothing', () async {
      await refresher.run();
      await refresher.run();

      expect(alerts.shown, isEmpty);
    });

    test('watches the page chosen, not always 100', () async {
      store.settings = const BackgroundSettings(alerts: true, alertPage: 300);
      await refresher.run();
      news = <String>['Sportnytt'];

      await refresher.run();

      expect(alerts.shown, <(int, String)>[(300, 'Sportnytt')]);
    });

    test('a changed page starts afresh: nothing is announced for it', () async {
      await refresher.run();
      store.settings = const BackgroundSettings(alerts: true, alertPage: 300);
      news = <String>['Helt annat'];

      await refresher.run();

      expect(alerts.shown, isEmpty);
    });

    test('with alerts off nothing is asked for or announced', () async {
      store.settings = const BackgroundSettings();

      await refresher.run();

      expect(fetcher.requests, isEmpty);
      expect(alerts.shown, isEmpty);
    });

    test(
      'a site that cannot be reached announces nothing, and loses nothing',
      () async {
        await refresher.run();
        final WatchState before = watch.state;
        fetcher.route('/api/get/', const NetworkException('down'));

        await expectLater(refresher.run(), completes);

        expect(alerts.shown, isEmpty);
        expect(watch.state, before);
      },
    );

    test(
      'with the app open, the news is remembered but not announced',
      () async {
        await refresher.run();
        news = <String>['Ny huvudrubrik', 'Gammal rubrik'];
        await refresher.run(alert: false);
        await refresher.run();

        expect(alerts.shown, isEmpty);
      },
    );
  });

  group('alerts and the widget together', () {
    test('on the same page ask the site once', () async {
      widget.installed = true;
      store.settings = const BackgroundSettings(alerts: true);

      await refresher.run();

      expect(fetcher.requests, hasLength(1));
      expect(widget.published, hasLength(1));
      expect(watch.state.page, 100);
    });

    test('on different pages ask for each', () async {
      widget.installed = true;
      store.settings = const BackgroundSettings(
        alerts: true,
        widgetPage: 104,
        alertPage: 300,
      );

      await refresher.run();

      expect(fetcher.requests.map((Uri u) => u.pathSegments.last), <String>[
        '104',
        '300',
      ]);
    });

    test(
      'a widget page that failed is not asked for again as the alert page',
      () async {
        widget.installed = true;
        fetcher.route('/api/get/', const NetworkException('down'));

        await refresher.run();

        expect(fetcher.requests, hasLength(1));
      },
    );
  });

  group('the job', () {
    test('runs for alerts alone, with no widget', () async {
      final FakeBackgroundScheduler scheduler = FakeBackgroundScheduler();
      final BackgroundCoordinator coordinator = BackgroundCoordinator(
        scheduler: scheduler,
        widget: widget,
        refresher: refresher,
      );

      await coordinator.apply(const BackgroundSettings(alerts: true));
      expect(scheduler.current, const Duration(hours: 1));

      await coordinator.apply(const BackgroundSettings());
      expect(scheduler.current, isNull);
    });
  });

  group('BackgroundSettings with alerts', () {
    test('start off, on page 100', () {
      expect(const BackgroundSettings().alerts, isFalse);
      expect(const BackgroundSettings().alertPage, 100);
    });

    test('survive a round trip, and a bad page is the default', () {
      const BackgroundSettings s = BackgroundSettings(
        alerts: true,
        alertPage: 300,
      );

      expect(BackgroundSettings.decode(s.encode()), s);
      expect(BackgroundSettings.decode('{"alertPage": 5}').alertPage, 100);
      expect(BackgroundSettings.decode('{"alerts": "yes"}').alerts, isFalse);
    });
  });
}
