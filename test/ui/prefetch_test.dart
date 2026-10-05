import 'package:codedbykay_text_tv/model/refresh_settings.dart';
import 'package:codedbykay_text_tv/model/text_tv_page.dart';
import 'package:codedbykay_text_tv/model/text_tv_session.dart';
import 'package:codedbykay_text_tv/ui/text_tv_keys.dart';
import 'package:codedbykay_text_tv/ui/text_tv_screen.dart';
import 'package:codedbykay_text_tv/ui/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fakes/english.dart';
import '../fakes/fake_text_tv_repository.dart';

/// A page with neighbours and a bottom row of two links: its read-ahead is
/// next, previous, then those two.
TextTvPage _page(int number, {List<String>? lines}) => TextTvPage(
  number: number,
  parts: <List<String>>[
    lines ??
        <String>['$number SVT Text', '', 'Sida $number', 'Före 101 Efter 102'],
  ],
  previous: number - 1,
  next: number + 1,
);

FakeTextTvRepository _repository() => FakeTextTvRepository(<int, TextTvPage>{
  for (int n = 100; n <= 399; n++) n: _page(n),
});

Future<void> _open(
  WidgetTester tester,
  FakeTextTvRepository repository, {
  int start = 300,
  RefreshSettings refresh = const RefreshSettings(),
  ValueChanged<RefreshSettings>? onRefreshChanged,
}) async {
  tester.view
    ..physicalSize = const Size(800, 2400)
    ..devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      theme: textTvTheme(),
      home: TextTvScreen(
        repository: repository,
        initial: TextTvSession(page: start),
        refresh: refresh,
        onRefreshChanged: onRefreshChanged,
      ),
    ),
  );
  // Just long enough for the page to arrive: the read-ahead clock starts then,
  // and the tests below read it off exactly.
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 50));
}

void _lifecycle(WidgetTester tester, {required bool visible}) {
  final List<AppLifecycleState> steps = visible
      ? <AppLifecycleState>[
          AppLifecycleState.hidden,
          AppLifecycleState.inactive,
          AppLifecycleState.resumed,
        ]
      : <AppLifecycleState>[
          AppLifecycleState.inactive,
          AppLifecycleState.hidden,
          AppLifecycleState.paused,
        ];
  for (final AppLifecycleState state in steps) {
    tester.binding.handleAppLifecycleStateChanged(state);
  }
}

const Duration _ms = Duration(milliseconds: 1);

void main() {
  group('reading ahead', () {
    testWidgets('next, previous, then the linked pages: one at a time', (
      WidgetTester tester,
    ) async {
      final FakeTextTvRepository repository = _repository();
      await _open(tester, repository);
      expect(repository.prefetched, isEmpty, reason: 'not straight away');

      await tester.pump(_ms * 600);
      expect(
        repository.prefetched,
        isEmpty,
        reason: 'a moment to see if the reader moves on',
      );

      await tester.pump(_ms * 150);
      expect(repository.prefetched, <int>[301]);

      await tester.pump(_ms * 250);
      expect(repository.prefetched, <int>[
        301,
      ], reason: 'a pause between pages');

      await tester.pump(_ms * 150);
      expect(repository.prefetched, <int>[301, 299]);

      await tester.pump(const Duration(seconds: 5));
      expect(repository.prefetched, <int>[301, 299, 101, 102]);
    });

    testWidgets('never more than a handful of pages for one page viewed', (
      WidgetTester tester,
    ) async {
      final FakeTextTvRepository repository = _repository();
      repository.pages[300] = _page(
        300,
        lines: <String>['Text', 'A 111 B 112 C 113 D 114 E 115 F 116'],
      );
      await _open(tester, repository);

      await tester.pump(const Duration(seconds: 30));

      expect(repository.prefetched, hasLength(4));
    });

    testWidgets('not at all when switched off', (WidgetTester tester) async {
      final FakeTextTvRepository repository = _repository();
      await _open(
        tester,
        repository,
        refresh: const RefreshSettings(prefetch: false),
      );

      await tester.pump(const Duration(seconds: 10));

      expect(repository.prefetched, isEmpty);
    });

    testWidgets('moving on drops the queue and starts one for the new page', (
      WidgetTester tester,
    ) async {
      final FakeTextTvRepository repository = _repository();
      await _open(tester, repository);
      await tester.pump(_ms * 300);

      await tester.tap(find.byKey(textTvNextKey));
      await tester.pumpAndSettle();
      await tester.pump(const Duration(seconds: 10));

      // Nothing of page 300's queue; page 301's own neighbours.
      expect(repository.prefetched.first, 302);
      expect(repository.prefetched, containsAll(<int>[302, 300]));
      expect(repository.prefetched, isNot(contains(299)));
    });

    testWidgets('a page left before the pause is over is never read ahead', (
      WidgetTester tester,
    ) async {
      final FakeTextTvRepository repository = _repository();
      await _open(tester, repository);

      // Page after page, faster than the pause.
      for (int i = 0; i < 4; i++) {
        await tester.tap(find.byKey(textTvNextKey));
        await tester.pump();
        await tester.pump(_ms * 200);
      }

      expect(repository.prefetched, isEmpty);
    });

    testWidgets(
      'an old copy shown because the site is out of reach starts none',
      (WidgetTester tester) async {
        final FakeTextTvRepository repository = _repository()
          ..failure = TextTvShown(
            _page(300),
            cachedAt: DateTime(2026, 10, 5, 9),
            readAt: DateTime(2026, 10, 5, 9),
          );
        await _open(tester, repository);

        await tester.pump(const Duration(seconds: 10));

        expect(repository.prefetched, isEmpty);
      },
    );

    testWidgets('a pull does not start it all over again', (
      WidgetTester tester,
    ) async {
      final FakeTextTvRepository repository = _repository();
      tester.view
        ..physicalSize = const Size(400, 800)
        ..devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp(
          theme: textTvTheme(),
          home: TextTvScreen(
            repository: repository,
            initial: const TextTvSession(page: 300),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.pump(const Duration(seconds: 5));
      final int once = repository.prefetched.length;

      await tester.fling(
        find.byType(SingleChildScrollView).first,
        const Offset(0, 400),
        1000,
      );
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle();
      await tester.pump(const Duration(seconds: 10));

      expect(repository.requests.last, (
        300,
        true,
      ), reason: 'the pull happened');
      expect(repository.prefetched, hasLength(once));
    });

    testWidgets('stops while the app is out of sight', (
      WidgetTester tester,
    ) async {
      final FakeTextTvRepository repository = _repository();
      await _open(tester, repository);
      await tester.pump(_ms * 300);

      _lifecycle(tester, visible: false);
      await tester.pump(const Duration(seconds: 10));

      expect(repository.prefetched, isEmpty);
    });

    testWidgets('can be switched off while a queue is waiting', (
      WidgetTester tester,
    ) async {
      final List<RefreshSettings> heard = <RefreshSettings>[];
      final FakeTextTvRepository repository = _repository();
      await _open(tester, repository, onRefreshChanged: heard.add);
      await tester.tap(find.byKey(textTvSettingsKey));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(textTvPrefetchKey));
      await tester.pumpAndSettle();
      expect(heard.last.prefetch, isFalse);
      final int before = repository.prefetched.length;

      await tester.pump(const Duration(seconds: 10));

      expect(repository.prefetched, hasLength(before));
    });
  });

  group('the setting', () {
    testWidgets('is on by default, in the refresh group', (
      WidgetTester tester,
    ) async {
      await _open(tester, _repository());
      await tester.tap(find.byKey(textTvSettingsKey));
      await tester.pumpAndSettle();

      expect(
        tester.widget<Switch>(find.byKey(textTvPrefetchKey)).value,
        isTrue,
      );
      expect(
        find.descendant(
          of: find.byKey(textTvSettingsGroupKey('refresh')),
          matching: find.byKey(textTvPrefetchKey),
        ),
        findsOneWidget,
      );
      expect(find.text(en.prefetch), findsOneWidget);
    });

    testWidgets('shows what was saved', (WidgetTester tester) async {
      await _open(
        tester,
        _repository(),
        refresh: const RefreshSettings(prefetch: false),
      );
      await tester.tap(find.byKey(textTvSettingsKey));
      await tester.pumpAndSettle();

      expect(
        tester.widget<Switch>(find.byKey(textTvPrefetchKey)).value,
        isFalse,
      );
    });

    testWidgets('changing it keeps the auto-refresh step', (
      WidgetTester tester,
    ) async {
      final List<RefreshSettings> heard = <RefreshSettings>[];
      await _open(
        tester,
        _repository(),
        refresh: const RefreshSettings(auto: 2),
        onRefreshChanged: heard.add,
      );
      await tester.tap(find.byKey(textTvSettingsKey));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(textTvPrefetchKey));
      await tester.pumpAndSettle();

      expect(heard.last, const RefreshSettings(auto: 2, prefetch: false));
    });
  });
}
