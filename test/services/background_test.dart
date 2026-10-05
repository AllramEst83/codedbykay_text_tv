import 'dart:convert';

import 'package:codedbykay_text_tv/model/background_settings.dart';
import 'package:codedbykay_text_tv/services/background_coordinator.dart';
import 'package:codedbykay_text_tv/services/background_refresher.dart';
import 'package:codedbykay_text_tv/services/background_settings_store.dart';
import 'package:codedbykay_text_tv/services/network_exception.dart';
import 'package:codedbykay_text_tv/services/open_page_service.dart';
import 'package:codedbykay_text_tv/services/text_tv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  late FakeBackgroundSettingsStore store;
  late DateTime now;
  late BackgroundRefresher refresher;
  setUp(() {
    fetcher = FakeHttpFetcher()
      ..route('/api/get/', (Uri url) {
        final int n = int.parse(url.pathSegments.last);
        return _page(n, <String>['Rubrik ett', 'Rubrik två']);
      });
    widget = FakeWidgetPlatform();
    store = FakeBackgroundSettingsStore();
    now = DateTime(2026, 10, 5, 12, 30);
    refresher = BackgroundRefresher(
      textTv: TextTv(fetcher: fetcher),
      settings: store,
      widget: widget,
      clock: () => now,
    );
  });

  group('BackgroundRefresher', () {
    test(
      'reads the widget\'s page and gives its headlines to the widget',
      () async {
        store.settings = const BackgroundSettings(widgetPage: 300);

        await refresher.run();

        expect(fetcher.requests.single.pathSegments.last, '300');
        expect(widget.published.single.page, 300);
        expect(widget.published.single.lines, <String>[
          'Rubrik ett',
          'Rubrik två',
        ]);
        expect(widget.published.single.updated, '12:30');
      },
    );

    test('asks for nothing when there is no widget on a home screen', () async {
      widget.installed = false;

      await refresher.run();

      expect(fetcher.requests, isEmpty);
      expect(widget.published, isEmpty);
    });

    test('a site that cannot be reached leaves the widget as it was', () async {
      fetcher.route('/api/get/', const NetworkException('down'));

      await expectLater(refresher.run(), completes);

      expect(widget.published, isEmpty);
    });

    test('a page not in broadcast leaves the widget as it was', () async {
      fetcher.route('/api/get/', '[]');

      await refresher.run();

      expect(widget.published, isEmpty);
    });

    test('never throws, whatever goes wrong', () async {
      fetcher.route('/api/get/', 'not json at all');

      await expectLater(refresher.run(), completes);
    });
  });

  group('BackgroundCoordinator', () {
    late FakeBackgroundScheduler scheduler;
    late BackgroundCoordinator coordinator;
    setUp(() {
      scheduler = FakeBackgroundScheduler();
      coordinator = BackgroundCoordinator(
        scheduler: scheduler,
        widget: widget,
        refresher: refresher,
        clock: () => now,
      );
    });

    test(
      'runs the job at the chosen interval while there is a widget',
      () async {
        await coordinator.apply(const BackgroundSettings(interval: 2));

        expect(scheduler.current, const Duration(hours: 3));
      },
    );

    test('stops the job when there is no widget', () async {
      await coordinator.apply(const BackgroundSettings());
      widget.installed = false;

      await coordinator.apply(const BackgroundSettings());

      expect(scheduler.current, isNull);
    });

    test('a changed interval replaces the schedule', () async {
      await coordinator.apply(const BackgroundSettings(interval: 0));
      await coordinator.apply(const BackgroundSettings(interval: 1));

      expect(scheduler.scheduled, <Duration>[
        const Duration(minutes: 30),
        const Duration(hours: 1),
      ]);
    });

    test('coming to the front refreshes the widget at once', () async {
      await coordinator.appResumed(const BackgroundSettings());

      expect(widget.published, hasLength(1));
      expect(scheduler.current, const Duration(hours: 1));
    });

    test('but not again within a few minutes', () async {
      await coordinator.appResumed(const BackgroundSettings());
      now = now.add(const Duration(minutes: 2));
      await coordinator.appResumed(const BackgroundSettings());

      expect(widget.published, hasLength(1));

      now = now.add(const Duration(minutes: 4));
      await coordinator.appResumed(const BackgroundSettings());
      expect(widget.published, hasLength(2));
    });

    test('with no widget, coming to the front asks for nothing', () async {
      widget.installed = false;

      await coordinator.appResumed(const BackgroundSettings());

      expect(fetcher.requests, isEmpty);
      expect(scheduler.current, isNull);
    });
  });

  group('PrefsBackgroundSettingsStore', () {
    setUp(() => SharedPreferences.setMockInitialValues(<String, Object>{}));

    test('a first run gets the defaults', () async {
      expect(
        await PrefsBackgroundSettingsStore().load(),
        BackgroundSettings.defaults,
      );
    });

    test('gives back what was saved, to a new store too', () async {
      await PrefsBackgroundSettingsStore().save(
        const BackgroundSettings(widgetPage: 377, interval: 2),
      );

      expect(
        await PrefsBackgroundSettingsStore().load(),
        const BackgroundSettings(widgetPage: 377, interval: 2),
      );
    });

    test('a damaged saved value gives the defaults', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{
        PrefsBackgroundSettingsStore.key: 'garbage',
      });

      expect(
        await PrefsBackgroundSettingsStore().load(),
        BackgroundSettings.defaults,
      );
    });
  });

  group('OpenPageService', () {
    test('hands over the pages asked for, in order', () async {
      final OpenPageService service = OpenPageService();
      final List<int> heard = <int>[];
      service.requests.listen(heard.add);

      service
        ..request(377)
        ..request(104);
      await Future<void>.delayed(Duration.zero);

      expect(heard, <int>[377, 104]);
      await service.dispose();
    });

    test('keeps a request made before anyone listens', () async {
      final OpenPageService service = OpenPageService();
      service.request(450);

      final List<int> heard = <int>[];
      service.requests.listen(heard.add);
      await Future<void>.delayed(Duration.zero);

      expect(heard, <int>[450]);
      await service.dispose();
    });

    test('closing twice is fine, and nothing is heard after it', () async {
      final OpenPageService service = OpenPageService();
      await service.dispose();

      expect(() => service.request(300), returnsNormally);
      await expectLater(service.dispose(), completes);
    });
  });
}
