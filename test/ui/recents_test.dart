import 'package:codedbykay_text_tv/messages.dart';
import 'package:codedbykay_text_tv/model/controls_settings.dart';
import 'package:codedbykay_text_tv/model/network_failure.dart';
import 'package:codedbykay_text_tv/model/saved_pages.dart';
import 'package:codedbykay_text_tv/model/text_tv_page.dart';
import 'package:codedbykay_text_tv/model/text_tv_session.dart';
import 'package:codedbykay_text_tv/ui/text_tv_keys.dart';
import 'package:codedbykay_text_tv/ui/text_tv_screen.dart';
import 'package:codedbykay_text_tv/ui/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fakes/fake_text_tv_repository.dart';

FakeTextTvRepository _repository() => FakeTextTvRepository(<int, TextTvPage>{
  for (int n = 100; n <= 799; n++)
    n: TextTvPage(
      number: n,
      parts: <List<String>>[
        <String>['$n SVT Text', '', 'Sida $n'],
      ],
      previous: n - 1,
      next: n + 1,
    ),
});

Future<void> _open(
  WidgetTester tester, {
  int start = 100,
  SavedPages saved = const SavedPages(),
  ValueChanged<SavedPages>? onSavedChanged,
  FakeTextTvRepository? repository,
}) async {
  tester.view
    ..physicalSize = const Size(800, 2400)
    ..devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      theme: textTvTheme(),
      home: TextTvScreen(
        repository: repository ?? _repository(),
        initial: TextTvSession(page: start),
        saved: saved,
        // Page numbers are typed on the always-on pad.
        controls: const ControlsSettings(quickEntry: true),
        onSavedChanged: onSavedChanged,
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _go(WidgetTester tester, int page) async {
  // Through a favourite chip or the arrows: whichever reaches the page.
  final Finder chip = find.byKey(textTvChipKey(page));
  if (chip.evaluate().isNotEmpty) {
    await tester.tap(chip);
  } else {
    for (final int digit in '$page'.split('').map(int.parse)) {
      await tester.tap(find.byKey(textTvDigitKey(digit)));
      await tester.pump();
    }
  }
  await tester.pumpAndSettle();
}

Future<void> _openRecents(WidgetTester tester) async {
  await tester.tap(find.byKey(textTvRecentsKey));
  await tester.pumpAndSettle();
}

void main() {
  group('remembering pages read', () {
    testWidgets('the page the app opens on counts', (
      WidgetTester tester,
    ) async {
      final List<SavedPages> heard = <SavedPages>[];
      await _open(tester, start: 377, onSavedChanged: heard.add);

      expect(heard.last.recents, <int>[377]);
    });

    testWidgets('each page read goes first, the latest at the front', (
      WidgetTester tester,
    ) async {
      final List<SavedPages> heard = <SavedPages>[];
      await _open(tester, onSavedChanged: heard.add);

      await _go(tester, 300);
      await _go(tester, 400);

      expect(heard.last.recents, <int>[400, 300, 100]);
    });

    testWidgets('a page read again moves to the front', (
      WidgetTester tester,
    ) async {
      final List<SavedPages> heard = <SavedPages>[];
      await _open(tester, onSavedChanged: heard.add);
      await _go(tester, 300);
      await _go(tester, 400);

      await _go(tester, 100);

      expect(heard.last.recents, <int>[100, 400, 300]);
    });

    testWidgets('a page that is not in broadcast is not remembered', (
      WidgetTester tester,
    ) async {
      final List<SavedPages> heard = <SavedPages>[];
      await _open(tester, onSavedChanged: heard.add);

      for (final int digit in <int>[8, 5, 5]) {
        await tester.tap(find.byKey(textTvDigitKey(digit)));
        await tester.pump();
      }
      await tester.pumpAndSettle();

      expect(find.text(Messages.pageNotBroadcast(855)), findsOneWidget);
      expect(heard.last.recents, isNot(contains(855)));
    });

    testWidgets('a failure is not remembered', (WidgetTester tester) async {
      final List<SavedPages> heard = <SavedPages>[];
      final FakeTextTvRepository repository = _repository();
      repository.failure = const TextTvFailed(NetworkFailure.offline);
      await _open(tester, onSavedChanged: heard.add, repository: repository);

      expect(heard.where((SavedPages s) => s.recents.isNotEmpty), isEmpty);
    });

    testWidgets('a refresh does not count as another visit', (
      WidgetTester tester,
    ) async {
      final List<SavedPages> heard = <SavedPages>[];
      await _open(tester, onSavedChanged: heard.add);
      await _go(tester, 300);
      final int before = heard.length;

      await tester.tap(find.byKey(textTvRefreshKey));
      await tester.pumpAndSettle();

      expect(heard.last.recents, <int>[300, 100]);
      expect(heard.length, before + 0, reason: 'no new report for a re-read');
    });

    testWidgets('only the latest dozen are kept', (WidgetTester tester) async {
      final List<SavedPages> heard = <SavedPages>[];
      await _open(
        tester,
        start: 200,
        saved: const SavedPages(favourites: <Favourite>[]),
        onSavedChanged: heard.add,
      );

      for (int i = 0; i < 14; i++) {
        await tester.tap(find.byKey(textTvNextKey));
        await tester.pumpAndSettle();
      }

      expect(heard.last.recents, hasLength(SavedPages.maxRecents));
      expect(heard.last.recents.first, 214);
    });
  });

  group('the history chip', () {
    testWidgets('starts the row of chips, and has a name for a screen reader', (
      WidgetTester tester,
    ) async {
      await _open(tester);

      expect(find.byKey(textTvRecentsKey), findsOneWidget);
      expect(
        tester.getTopLeft(find.byKey(textTvRecentsKey)).dx,
        lessThan(tester.getTopLeft(find.byKey(textTvChipKey(100))).dx),
      );
      expect(find.bySemanticsLabel(Messages.recentPages), findsOneWidget);
    });

    testWidgets('is there with no favourites too, beside the hint', (
      WidgetTester tester,
    ) async {
      await _open(tester, saved: const SavedPages(favourites: <Favourite>[]));

      expect(find.byKey(textTvRecentsKey), findsOneWidget);
      expect(find.byKey(textTvFavouritesHintKey), findsOneWidget);
    });

    testWidgets('opens the pages read last, the latest first', (
      WidgetTester tester,
    ) async {
      await _open(tester);
      await _go(tester, 300);
      await _go(tester, 400);

      await _openRecents(tester);

      expect(find.text(Messages.recentsTitle), findsOneWidget);
      final double top200 = tester
          .getTopLeft(find.byKey(textTvRecentKey(300)))
          .dy;
      final double top100 = tester
          .getTopLeft(find.byKey(textTvRecentKey(100)))
          .dy;
      expect(top200, lessThan(top100), reason: '300 was read after 100');
    });

    testWidgets('leaves out the page on show', (WidgetTester tester) async {
      await _open(tester);
      await _go(tester, 300);

      await _openRecents(tester);

      expect(find.byKey(textTvRecentKey(300)), findsNothing);
      expect(find.byKey(textTvRecentKey(100)), findsOneWidget);
    });

    testWidgets('names the ones that are favourites, the rest by number', (
      WidgetTester tester,
    ) async {
      await _open(tester);
      await _go(tester, 300);
      await _go(tester, 400);
      await tester.tap(find.byKey(textTvStarKey));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(textTvStarKey));
      await tester.pumpAndSettle();
      await _go(tester, 555);

      await _openRecents(tester);

      expect(
        find.descendant(
          of: find.byKey(textTvRecentKey(300)),
          matching: find.text('300 SPORT'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byKey(textTvRecentKey(400)),
          matching: find.text('400'),
        ),
        findsOneWidget,
        reason: 'starred again, so no longer named',
      );
    });

    testWidgets('a tap opens the page and closes the list', (
      WidgetTester tester,
    ) async {
      final FakeTextTvRepository repository = _repository();
      await _open(tester, repository: repository);
      await _go(tester, 300);
      await _go(tester, 555);
      await _openRecents(tester);

      await tester.tap(find.byKey(textTvRecentKey(300)));
      await tester.pumpAndSettle();

      expect(find.text(Messages.recentsTitle), findsNothing);
      expect(repository.requests.last, (300, false));
      expect(
        find.descendant(
          of: find.byKey(textTvNumberKey),
          matching: find.text('300'),
        ),
        findsOneWidget,
      );
    });

    testWidgets('says so when there is nothing else read yet', (
      WidgetTester tester,
    ) async {
      await _open(tester);

      await _openRecents(tester);

      expect(find.byKey(textTvRecentsEmptyKey), findsOneWidget);
      expect(find.text(Messages.recentsEmpty), findsOneWidget);
    });

    testWidgets(
      'CLEAR LIST empties them, closes the list, keeps the favourites',
      (WidgetTester tester) async {
        final List<SavedPages> heard = <SavedPages>[];
        await _open(tester, onSavedChanged: heard.add);
        await _go(tester, 300);
        await _go(tester, 555);
        await _openRecents(tester);

        await tester.tap(find.byKey(textTvRecentsClearKey));
        await tester.pumpAndSettle();

        expect(find.text(Messages.recentsTitle), findsNothing);
        expect(heard.last.recents, isEmpty);
        expect(heard.last.favourites, defaultFavourites);

        await _openRecents(tester);
        expect(find.byKey(textTvRecentsEmptyKey), findsOneWidget);
      },
    );

    testWidgets('CLEAR LIST is off when there is nothing to clear', (
      WidgetTester tester,
    ) async {
      await _open(tester);
      await _openRecents(tester);

      final InkWell clear = tester.widget<InkWell>(
        find.descendant(
          of: find.byKey(textTvRecentsClearKey),
          matching: find.byType(InkWell),
        ),
      );
      expect(clear.onTap, isNull);
    });

    testWidgets('opens with the pages saved from last time', (
      WidgetTester tester,
    ) async {
      await _open(
        tester,
        start: 555,
        saved: const SavedPages().visited(300).visited(400),
      );

      await _openRecents(tester);

      expect(find.byKey(textTvRecentKey(400)), findsOneWidget);
      expect(find.byKey(textTvRecentKey(300)), findsOneWidget);
    });
  });
}
