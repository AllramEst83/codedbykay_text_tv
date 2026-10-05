import 'package:codedbykay_text_tv/model/saved_pages.dart';
import 'package:codedbykay_text_tv/model/text_tv_page.dart';
import 'package:codedbykay_text_tv/model/text_tv_session.dart';
import 'package:codedbykay_text_tv/ui/text_tv_keys.dart';
import 'package:codedbykay_text_tv/ui/text_tv_screen.dart';
import 'package:codedbykay_text_tv/ui/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fakes/english.dart';
import '../fakes/fake_text_tv_repository.dart';

FakeTextTvRepository _repository() => FakeTextTvRepository(<int, TextTvPage>{
  for (int n = 100; n <= 899; n++)
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
        onSavedChanged: onSavedChanged,
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Icon _starIcon(WidgetTester tester) => tester.widget<Icon>(
  find.descendant(of: find.byKey(textTvStarKey), matching: find.byType(Icon)),
);

double _chipX(WidgetTester tester, int page) =>
    tester.getTopLeft(find.byKey(textTvChipKey(page))).dx;

void main() {
  group('the chips', () {
    testWidgets('are the six built-in favourites to start with, in order', (
      WidgetTester tester,
    ) async {
      await _open(tester);

      final List<int> pages = <int>[100, 101, 104, 300, 400, 700];
      for (final int page in pages) {
        expect(
          find.byKey(textTvChipKey(page)),
          findsOneWidget,
          reason: '$page',
        );
      }
      for (int i = 1; i < pages.length; i++) {
        expect(
          _chipX(tester, pages[i]),
          greaterThan(_chipX(tester, pages[i - 1])),
        );
      }
      expect(find.text('100 NEWS'), findsOneWidget);
      expect(find.text('700 INDEX'), findsOneWidget);
    });

    testWidgets(
      'show the saved favourites instead, a bare page as its number',
      (WidgetTester tester) async {
        await _open(
          tester,
          saved: const SavedPages(
            favourites: <Favourite>[Favourite(377), Favourite(450, 'EKONOMI')],
          ),
        );

        expect(find.byKey(textTvChipKey(377)), findsOneWidget);
        expect(find.text('377'), findsWidgets);
        expect(find.text('450 EKONOMI'), findsOneWidget);
        expect(find.byKey(textTvChipKey(300)), findsNothing);
      },
    );

    testWidgets('open their page when tapped', (WidgetTester tester) async {
      final FakeTextTvRepository repository = _repository();
      await _open(
        tester,
        repository: repository,
        saved: const SavedPages(favourites: <Favourite>[Favourite(377)]),
      );

      await tester.tap(find.byKey(textTvChipKey(377)));
      await tester.pumpAndSettle();

      expect(repository.requests.last, (377, false));
    });

    testWidgets('with none, say how to add one', (WidgetTester tester) async {
      await _open(tester, saved: const SavedPages(favourites: <Favourite>[]));

      expect(find.byKey(textTvFavouritesHintKey), findsOneWidget);
      expect(find.text(en.favouritesHint), findsOneWidget);
      expect(find.byKey(textTvChipKey(100)), findsNothing);
    });
  });

  group('the star', () {
    testWidgets('is lit on a favourite and not on any other page', (
      WidgetTester tester,
    ) async {
      await _open(tester, start: 100);
      expect(_starIcon(tester).icon, Icons.star);

      await tester.pumpWidget(const SizedBox());
      await _open(tester, start: 377);
      expect(_starIcon(tester).icon, Icons.star_border);
    });

    testWidgets('adds the page, as the last chip, and reports it', (
      WidgetTester tester,
    ) async {
      final List<SavedPages> heard = <SavedPages>[];
      await _open(tester, start: 377, onSavedChanged: heard.add);
      expect(find.byKey(textTvChipKey(377)), findsNothing);

      await tester.tap(find.byKey(textTvStarKey));
      await tester.pumpAndSettle();

      expect(find.byKey(textTvChipKey(377)), findsOneWidget);
      expect(_chipX(tester, 377), greaterThan(_chipX(tester, 700)));
      expect(_starIcon(tester).icon, Icons.star);
      expect(heard.last.isFavourite(377), isTrue);
      expect(heard.last.favourites, hasLength(7));
    });

    testWidgets('takes the page off again, and reports it', (
      WidgetTester tester,
    ) async {
      final List<SavedPages> heard = <SavedPages>[];
      await _open(tester, start: 300, onSavedChanged: heard.add);

      await tester.tap(find.byKey(textTvStarKey));
      await tester.pumpAndSettle();

      expect(find.byKey(textTvChipKey(300)), findsNothing);
      expect(_starIcon(tester).icon, Icons.star_border);
      expect(heard.last.isFavourite(300), isFalse);
      expect(heard.last.favourites, hasLength(5));
    });

    testWidgets('follows the page you move to', (WidgetTester tester) async {
      await _open(tester, start: 104);
      expect(_starIcon(tester).icon, Icons.star);

      await tester.tap(find.byKey(textTvNextKey));
      await tester.pumpAndSettle();
      expect(_starIcon(tester).icon, Icons.star_border);

      await tester.tap(find.byKey(textTvPrevKey));
      await tester.pumpAndSettle();
      expect(_starIcon(tester).icon, Icons.star);
    });

    testWidgets('says what it will do, for a screen reader', (
      WidgetTester tester,
    ) async {
      await _open(tester, start: 377);
      expect(find.bySemanticsLabel(en.addFavourite), findsOneWidget);

      await tester.tap(find.byKey(textTvStarKey));
      await tester.pumpAndSettle();
      expect(find.bySemanticsLabel(en.removeFavourite), findsOneWidget);
    });

    testWidgets('does nothing more once the list is full', (
      WidgetTester tester,
    ) async {
      final List<SavedPages> heard = <SavedPages>[];
      await _open(
        tester,
        start: 800,
        saved: SavedPages(
          favourites: <Favourite>[
            for (int i = 0; i < SavedPages.maxFavourites; i++)
              Favourite(200 + i),
          ],
        ),
        onSavedChanged: heard.add,
      );

      await tester.tap(find.byKey(textTvStarKey));
      await tester.pumpAndSettle();

      // The visit to the page is reported; nothing is starred.
      for (final SavedPages reported in heard) {
        expect(reported.isFavourite(800), isFalse);
        expect(reported.favourites, hasLength(SavedPages.maxFavourites));
      }
      expect(find.byKey(textTvChipKey(800)), findsNothing);
    });

    testWidgets('a page removed and added again still has its section name', (
      WidgetTester tester,
    ) async {
      await _open(tester, start: 300);

      await tester.tap(find.byKey(textTvStarKey));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(textTvStarKey));
      await tester.pumpAndSettle();

      expect(find.text('300 SPORT'), findsOneWidget);
      expect(find.byKey(textTvChipKey(300)), findsOneWidget);
    });
  });

  group('in the settings page', () {
    Future<void> openSettings(WidgetTester tester) async {
      await tester.tap(find.byKey(textTvSettingsKey));
      await tester.pumpAndSettle();
    }

    testWidgets('has its own group, saying how many are saved', (
      WidgetTester tester,
    ) async {
      await _open(tester);
      await openSettings(tester);

      expect(find.byKey(textTvSettingsGroupKey('favourites')), findsOneWidget);
      expect(
        find.text(en.favouritesCount(6, SavedPages.maxFavourites)),
        findsOneWidget,
      );
    });

    testWidgets('RESET is off while the favourites are the built-in ones', (
      WidgetTester tester,
    ) async {
      await _open(tester);
      await openSettings(tester);

      final InkWell reset = tester.widget<InkWell>(
        find.descendant(
          of: find.byKey(textTvFavouritesResetKey),
          matching: find.byType(InkWell),
        ),
      );
      expect(reset.onTap, isNull);
    });

    testWidgets('RESET brings the six back, and reports it', (
      WidgetTester tester,
    ) async {
      final List<SavedPages> heard = <SavedPages>[];
      await _open(
        tester,
        saved: const SavedPages(favourites: <Favourite>[Favourite(377)]),
        onSavedChanged: heard.add,
      );
      await openSettings(tester);

      await tester.tap(find.byKey(textTvFavouritesResetKey));
      await tester.pumpAndSettle();

      expect(heard.last.favourites, defaultFavourites);
      await tester.tap(find.byKey(textTvSettingsBackKey));
      await tester.pumpAndSettle();
      expect(find.byKey(textTvChipKey(700)), findsOneWidget);
      expect(find.byKey(textTvChipKey(377)), findsNothing);
    });

    testWidgets('the count follows a page starred meanwhile', (
      WidgetTester tester,
    ) async {
      await _open(tester, start: 377);
      await tester.tap(find.byKey(textTvStarKey));
      await tester.pumpAndSettle();

      await openSettings(tester);

      expect(
        find.text(en.favouritesCount(7, SavedPages.maxFavourites)),
        findsOneWidget,
      );
    });
  });
}
