import 'dart:async';

import 'package:codedbykay_text_tv/messages.dart';
import 'package:codedbykay_text_tv/model/reader_settings.dart';
import 'package:codedbykay_text_tv/model/refresh_settings.dart';
import 'package:codedbykay_text_tv/model/text_tv_page.dart';
import 'package:codedbykay_text_tv/services/text_tv_repository.dart';
import 'package:codedbykay_text_tv/ui/text_tv_keys.dart';
import 'package:codedbykay_text_tv/ui/text_tv_screen.dart';
import 'package:codedbykay_text_tv/ui/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fakes/fake_text_tv_repository.dart';

TextTvPage _page(int number, String text, {List<List<String>>? parts}) =>
    TextTvPage(
      number: number,
      parts:
          parts ??
          <List<String>>[
            <String>['$number SVT Text', '', text],
          ],
      previous: number - 1,
      next: number + 1,
    );

/// A phone-sized screen: a pull is measured against the height it has.
const Size _phone = Size(400, 800);

/// The time the screen and the repository both say it is, moved by the tests.
class _Clock {
  DateTime now = DateTime(2026, 10, 5, 14, 30);
  DateTime call() => now;
}

Future<void> _open(
  WidgetTester tester,
  TextTvRepository repository, {
  _Clock? clock,
  RefreshSettings refresh = const RefreshSettings(),
  ReaderSettings reader = const ReaderSettings(),
  ValueChanged<RefreshSettings>? onRefreshChanged,
  Size size = const Size(800, 2400),
}) async {
  tester.view
    ..physicalSize = size
    ..devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      theme: textTvTheme(),
      home: TextTvScreen(
        repository: repository,
        refresh: refresh,
        reader: reader,
        onRefreshChanged: onRefreshChanged,
        clock: (clock ?? _Clock()).call,
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Finder _text(String text) => find.textContaining(text, findRichText: true);

/// Moves the app out of sight or back, one lifecycle step at a time, as the
/// system does.
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

int _freshReads(FakeTextTvRepository r) =>
    r.requests.where(((int, bool) q) => q.$2).length;

/// A repository whose answer is held back until [answer], to see what the
/// screen shows while it waits.
class _SlowRepository implements TextTvRepository {
  _SlowRepository(this.first);

  final TextTvPage first;
  Completer<TextTvResult>? _pending;
  final List<(int, bool)> requests = <(int, bool)>[];

  void answer(TextTvResult result) => _pending!.complete(result);

  @override
  Future<TextTvResult> page(int number, {bool fresh = false}) {
    requests.add((number, fresh));
    if (!fresh) return Future<TextTvResult>.value(TextTvShown(first));
    _pending = Completer<TextTvResult>();
    return _pending!.future;
  }

  @override
  Future<TextTvShown?> cached(int number) async => null;

  @override
  Future<void> prefetch(int number) async {}
}

void main() {
  group('the updated time', () {
    testWidgets('says when the page was read', (WidgetTester tester) async {
      final _Clock clock = _Clock();
      await _open(
        tester,
        FakeTextTvRepository(<int, TextTvPage>{
          100: _page(100, 'Hej'),
        }, clock.call),
        clock: clock,
      );

      expect(
        tester.widget<Text>(find.byKey(textTvUpdatedKey)).data,
        Messages.updated('14:30'),
      );
    });

    testWidgets('is not shown for an old copy, which has its own note', (
      WidgetTester tester,
    ) async {
      final FakeTextTvRepository repository =
          FakeTextTvRepository(<int, TextTvPage>{100: _page(100, 'Hej')})
            ..failure = TextTvShown(
              _page(100, 'Hej'),
              cachedAt: DateTime(2026, 10, 5, 9),
              readAt: DateTime(2026, 10, 5, 9),
            );
      await _open(tester, repository);

      expect(find.byKey(textTvUpdatedKey), findsNothing);
      expect(find.byKey(textTvOfflineKey), findsOneWidget);
    });

    testWidgets('moves on when the page is read again', (
      WidgetTester tester,
    ) async {
      final _Clock clock = _Clock();
      final FakeTextTvRepository repository = FakeTextTvRepository(
        <int, TextTvPage>{100: _page(100, 'Hej')},
        clock.call,
      );
      await _open(tester, repository, clock: clock);

      clock.now = DateTime(2026, 10, 5, 14, 41);
      await tester.tap(find.byKey(textTvRefreshKey));
      await tester.pumpAndSettle();

      expect(
        tester.widget<Text>(find.byKey(textTvUpdatedKey)).data,
        Messages.updated('14:41'),
      );
    });
  });

  group('pulling the page down', () {
    Future<void> pull(WidgetTester tester) async {
      await tester.fling(
        find.byType(SingleChildScrollView).first,
        const Offset(0, 400),
        1000,
      );
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
    }

    testWidgets('reads the page again, fresh', (WidgetTester tester) async {
      final FakeTextTvRepository repository = FakeTextTvRepository(
        <int, TextTvPage>{100: _page(100, 'Gammal text')},
      );
      await _open(tester, repository, size: _phone);
      repository.pages[100] = _page(100, 'Ny text');

      await pull(tester);
      await tester.pumpAndSettle();

      expect(repository.requests.last, (100, true));
    });

    testWidgets('keeps the page on show until the new one is here', (
      WidgetTester tester,
    ) async {
      final _SlowRepository repository = _SlowRepository(
        _page(
          100,
          'Gammal',
          parts: <List<String>>[
            <String>['100 SVT Text', '', 'Rad ett', 'Rad två'],
          ],
        ),
      );
      await _open(tester, repository, size: _phone);
      expect(find.text(Messages.loading), findsNothing);

      await pull(tester);

      // Asked for, not yet answered: the old page is still there, with no
      // LOADING screen in its place.
      expect(repository.requests.last, (100, true));
      expect(find.text(Messages.loading), findsNothing);
      expect(find.byType(RefreshProgressIndicator), findsOneWidget);

      repository.answer(
        TextTvShown(
          _page(
            100,
            'Ny',
            parts: <List<String>>[
              <String>['100 SVT Text', '', 'Rad ett', 'Rad två', 'Rad tre'],
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(RefreshProgressIndicator), findsNothing);
    });

    testWidgets('works in reader mode too', (WidgetTester tester) async {
      final FakeTextTvRepository repository = FakeTextTvRepository(
        <int, TextTvPage>{100: _page(100, 'Gammal text')},
      );
      await _open(
        tester,
        repository,
        size: _phone,
        reader: const ReaderSettings(enabled: true),
      );
      repository.pages[100] = _page(100, 'Ny text som är ny nog');
      expect(_text('Gammal text'), findsOneWidget);

      await tester.fling(
        find.byType(ListView).first,
        const Offset(0, 400),
        1000,
      );
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle();

      expect(repository.requests.last, (100, true));
      expect(_text('Ny text'), findsOneWidget);
      expect(_text('Gammal text'), findsNothing);
    });

    testWidgets('a failure leaves the page and says why', (
      WidgetTester tester,
    ) async {
      final FakeTextTvRepository repository = FakeTextTvRepository(
        <int, TextTvPage>{100: _page(100, 'Hej')},
      );
      await _open(tester, repository, size: _phone);
      repository.failure = const TextTvFailed('No signal');

      await pull(tester);
      await tester.pumpAndSettle();

      expect(find.text('NO SIGNAL'), findsOneWidget, reason: 'the message');
      expect(find.byKey(textTvUpdatedKey), findsOneWidget, reason: 'the page');
      expect(find.byKey(textTvRetryKey), findsNothing);
    });

    testWidgets('on a failed page it tries again and shows the page', (
      WidgetTester tester,
    ) async {
      final FakeTextTvRepository repository = FakeTextTvRepository(
        <int, TextTvPage>{100: _page(100, 'Hej igen')},
      )..failure = const TextTvFailed('No signal');
      await _open(tester, repository, size: _phone);
      expect(find.byKey(textTvRetryKey), findsOneWidget);

      repository.failure = null;
      await pull(tester);
      await tester.pumpAndSettle();

      expect(find.byKey(textTvRetryKey), findsNothing);
      expect(find.byKey(textTvUpdatedKey), findsOneWidget);
    });
  });

  group('refreshing by itself', () {
    testWidgets('never, unless the settings say so', (
      WidgetTester tester,
    ) async {
      final FakeTextTvRepository repository = FakeTextTvRepository(
        <int, TextTvPage>{100: _page(100, 'Hej')},
      );
      await _open(tester, repository);

      await tester.pump(const Duration(minutes: 30));

      expect(_freshReads(repository), 0);
    });

    for (final (int step, Duration every) in <(int, Duration)>[
      (1, const Duration(seconds: 30)),
      (2, const Duration(seconds: 60)),
      (3, const Duration(minutes: 2)),
    ]) {
      testWidgets('reads the page every $every', (WidgetTester tester) async {
        final FakeTextTvRepository repository = FakeTextTvRepository(
          <int, TextTvPage>{100: _page(100, 'Hej')},
        );
        await _open(tester, repository, refresh: RefreshSettings(auto: step));

        await tester.pump(every - const Duration(seconds: 1));
        expect(_freshReads(repository), 0, reason: 'not yet');

        await tester.pump(const Duration(seconds: 2));
        expect(_freshReads(repository), 1);
        expect(repository.requests.last, (100, true));

        await tester.pump(every);
        expect(_freshReads(repository), 2);
      });
    }

    testWidgets('shows the new page without a loading screen', (
      WidgetTester tester,
    ) async {
      final FakeTextTvRepository repository = FakeTextTvRepository(
        <int, TextTvPage>{100: _page(100, 'Gammal text')},
      );
      await _open(
        tester,
        repository,
        refresh: const RefreshSettings(auto: 1),
        reader: const ReaderSettings(enabled: true),
      );
      expect(_text('Gammal text'), findsOneWidget);
      repository.pages[100] = _page(100, 'Ny text');

      await tester.pump(const Duration(seconds: 31));

      expect(_text('Ny text'), findsOneWidget);
      expect(find.text(Messages.readerLoading), findsNothing);
    });

    testWidgets('keeps the part you were reading', (WidgetTester tester) async {
      final FakeTextTvRepository repository = FakeTextTvRepository(
        <int, TextTvPage>{
          100: _page(
            100,
            '',
            parts: <List<String>>[
              <String>['100 SVT Text', '', 'Del ett'],
              <String>['100 SVT Text', '', 'Del två'],
            ],
          ),
        },
      );
      await _open(
        tester,
        repository,
        refresh: const RefreshSettings(auto: 1),
        reader: const ReaderSettings(enabled: true),
      );
      await tester.tap(find.byKey(textTvPartNextKey));
      await tester.pumpAndSettle();
      expect(_text('Del två'), findsOneWidget);

      await tester.pump(const Duration(seconds: 31));

      expect(_text('Del två'), findsOneWidget);
      expect(find.text('${Messages.part} 2/2'), findsOneWidget);
    });

    testWidgets('brings the part back in range if the page got shorter', (
      WidgetTester tester,
    ) async {
      final FakeTextTvRepository repository = FakeTextTvRepository(
        <int, TextTvPage>{
          100: _page(
            100,
            '',
            parts: <List<String>>[
              <String>['100 SVT Text', '', 'Del ett'],
              <String>['100 SVT Text', '', 'Del två'],
            ],
          ),
        },
      );
      await _open(
        tester,
        repository,
        refresh: const RefreshSettings(auto: 1),
        reader: const ReaderSettings(enabled: true),
      );
      await tester.tap(find.byKey(textTvPartNextKey));
      await tester.pumpAndSettle();
      repository.pages[100] = _page(100, 'Bara en del nu');

      await tester.pump(const Duration(seconds: 31));

      expect(_text('Bara en del nu'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('a failure or an old copy never replaces a good page', (
      WidgetTester tester,
    ) async {
      final FakeTextTvRepository repository = FakeTextTvRepository(
        <int, TextTvPage>{100: _page(100, 'Bra text')},
      );
      await _open(
        tester,
        repository,
        refresh: const RefreshSettings(auto: 1),
        reader: const ReaderSettings(enabled: true),
      );

      repository.failure = const TextTvFailed('No signal');
      await tester.pump(const Duration(seconds: 31));
      expect(_text('Bra text'), findsOneWidget);
      expect(find.byKey(textTvRetryKey), findsNothing);

      repository.failure = TextTvShown(
        _page(100, 'Gammal kopia'),
        cachedAt: DateTime(2026, 10, 1),
        readAt: DateTime(2026, 10, 1),
      );
      await tester.pump(const Duration(seconds: 31));
      expect(_text('Bra text'), findsOneWidget);
      expect(_text('Gammal kopia'), findsNothing);
      expect(find.byKey(textTvOfflineKey), findsNothing);
    });

    testWidgets('an answer for a page you have left is thrown away', (
      WidgetTester tester,
    ) async {
      final _SlowRepository repository = _SlowRepository(
        _page(100, 'Sida hundra'),
      );
      await _open(
        tester,
        repository,
        refresh: const RefreshSettings(auto: 1),
        reader: const ReaderSettings(enabled: true),
      );
      await tester.pump(const Duration(seconds: 31));
      expect(repository.requests.last, (100, true));

      // Moves on before the answer arrives.
      await tester.tap(find.byKey(textTvChipKey(300)));
      await tester.pump();
      repository.answer(TextTvShown(_page(100, 'Sena svaret')));
      await tester.pumpAndSettle();

      expect(_text('Sena svaret'), findsNothing);
    });

    testWidgets('one refresh at a time', (WidgetTester tester) async {
      final _SlowRepository repository = _SlowRepository(_page(100, 'Hej'));
      await _open(tester, repository, refresh: const RefreshSettings(auto: 1));

      await tester.pump(const Duration(seconds: 31));
      await tester.pump(const Duration(seconds: 31));
      await tester.pump(const Duration(seconds: 31));

      expect(
        repository.requests.where(((int, bool) q) => q.$2).length,
        1,
        reason: 'the first answer has not come, so no second is asked for',
      );
    });

    testWidgets('stops while the app is out of sight, and starts again', (
      WidgetTester tester,
    ) async {
      final _Clock clock = _Clock();
      final FakeTextTvRepository repository = FakeTextTvRepository(
        <int, TextTvPage>{100: _page(100, 'Hej')},
        clock.call,
      );
      await _open(
        tester,
        repository,
        clock: clock,
        refresh: const RefreshSettings(auto: 1),
      );

      _lifecycle(tester, visible: false);
      await tester.pump(const Duration(minutes: 5));
      expect(_freshReads(repository), 0);

      _lifecycle(tester, visible: true);
      await tester.pump();
      final int afterResume = _freshReads(repository);
      await tester.pump(const Duration(seconds: 31));
      expect(_freshReads(repository), greaterThan(afterResume));
    });

    testWidgets('waits while the settings page is open over it', (
      WidgetTester tester,
    ) async {
      final FakeTextTvRepository repository = FakeTextTvRepository(
        <int, TextTvPage>{100: _page(100, 'Hej')},
      );
      await _open(tester, repository, refresh: const RefreshSettings(auto: 1));
      await tester.tap(find.byKey(textTvSettingsKey));
      await tester.pumpAndSettle();

      await tester.pump(const Duration(minutes: 3));
      expect(_freshReads(repository), 0);

      await tester.tap(find.byKey(textTvSettingsBackKey));
      await tester.pumpAndSettle();
      await tester.pump(const Duration(seconds: 31));
      expect(_freshReads(repository), 1);
    });
  });

  group('coming back to the app', () {
    testWidgets('reads a page that was left for a while', (
      WidgetTester tester,
    ) async {
      final _Clock clock = _Clock();
      final FakeTextTvRepository repository = FakeTextTvRepository(
        <int, TextTvPage>{100: _page(100, 'Gammal text')},
        clock.call,
      );
      await _open(
        tester,
        repository,
        clock: clock,
        reader: const ReaderSettings(enabled: true),
      );
      repository.pages[100] = _page(100, 'Ny text');

      _lifecycle(tester, visible: false);
      clock.now = clock.now.add(const Duration(minutes: 3));
      _lifecycle(tester, visible: true);
      await tester.pumpAndSettle();

      expect(repository.requests.last, (100, true));
      expect(_text('Ny text'), findsOneWidget);
    });

    testWidgets('leaves a page that was read a moment ago alone', (
      WidgetTester tester,
    ) async {
      final _Clock clock = _Clock();
      final FakeTextTvRepository repository = FakeTextTvRepository(
        <int, TextTvPage>{100: _page(100, 'Hej')},
        clock.call,
      );
      await _open(tester, repository, clock: clock);

      _lifecycle(tester, visible: false);
      clock.now = clock.now.add(const Duration(seconds: 90));
      _lifecycle(tester, visible: true);
      await tester.pumpAndSettle();

      expect(_freshReads(repository), 0);
    });
  });

  group('the setting', () {
    testWidgets('is on the settings page, showing what is set', (
      WidgetTester tester,
    ) async {
      await _open(
        tester,
        FakeTextTvRepository(<int, TextTvPage>{100: _page(100, 'Hej')}),
        refresh: const RefreshSettings(auto: 2),
      );

      await tester.tap(find.byKey(textTvSettingsKey));
      await tester.pumpAndSettle();

      expect(find.text(Messages.autoRefresh), findsOneWidget);
      expect(
        find.text(Messages.autoRefreshValue(const Duration(seconds: 60))),
        findsOneWidget,
      );
      expect(tester.widget<Slider>(find.byKey(textTvAutoRefreshKey)).value, 2);
    });

    testWidgets('reports a change, and the page starts refreshing at once', (
      WidgetTester tester,
    ) async {
      final List<RefreshSettings> heard = <RefreshSettings>[];
      final FakeTextTvRepository repository = FakeTextTvRepository(
        <int, TextTvPage>{100: _page(100, 'Hej')},
      );
      await _open(tester, repository, onRefreshChanged: heard.add);
      await tester.tap(find.byKey(textTvSettingsKey));
      await tester.pumpAndSettle();

      await tester.drag(
        find.byKey(textTvAutoRefreshKey),
        const Offset(3000, 0),
      );
      await tester.pumpAndSettle();
      expect(
        heard.last,
        RefreshSettings(auto: autoRefreshIntervals.length - 1),
      );

      await tester.tap(find.byKey(textTvSettingsBackKey));
      await tester.pumpAndSettle();
      await tester.pump(const Duration(minutes: 2, seconds: 1));
      expect(_freshReads(repository), 1);
    });

    testWidgets('can be turned off again', (WidgetTester tester) async {
      final List<RefreshSettings> heard = <RefreshSettings>[];
      final FakeTextTvRepository repository = FakeTextTvRepository(
        <int, TextTvPage>{100: _page(100, 'Hej')},
      );
      await _open(
        tester,
        repository,
        refresh: const RefreshSettings(auto: 1),
        onRefreshChanged: heard.add,
      );
      await tester.tap(find.byKey(textTvSettingsKey));
      await tester.pumpAndSettle();

      await tester.drag(
        find.byKey(textTvAutoRefreshKey),
        const Offset(-3000, 0),
      );
      await tester.pumpAndSettle();
      expect(heard.last, const RefreshSettings());

      await tester.tap(find.byKey(textTvSettingsBackKey));
      await tester.pumpAndSettle();
      await tester.pump(const Duration(minutes: 10));
      expect(_freshReads(repository), 0);
    });
  });
}
