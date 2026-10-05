import 'package:codedbykay_text_tv/model/saved_pages.dart';
import 'package:codedbykay_text_tv/model/text_tv_page.dart';
import 'package:codedbykay_text_tv/model/text_tv_session.dart';
import 'package:codedbykay_text_tv/services/shortcut_service.dart';
import 'package:codedbykay_text_tv/ui/text_tv_keys.dart';
import 'package:codedbykay_text_tv/ui/text_tv_screen.dart';
import 'package:codedbykay_text_tv/ui/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fakes/fake_shortcut_platform.dart';
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
  required ShortcutService? shortcuts,
  int start = 100,
  SavedPages saved = const SavedPages(),
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
        shortcuts: shortcuts,
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Finder _number(String text) =>
    find.descendant(of: find.byKey(textTvNumberKey), matching: find.text(text));

List<String> _types(FakeShortcutPlatform p) =>
    p.current.map((e) => e.type).toList();

void main() {
  late FakeShortcutPlatform platform;
  late ShortcutService service;
  setUp(() {
    platform = FakeShortcutPlatform();
    service = ShortcutService(platform);
  });

  group('the icon shortcuts follow the favourites', () {
    testWidgets('are set when the app starts, to the first four', (
      WidgetTester tester,
    ) async {
      await service.start();
      await _open(tester, shortcuts: service);

      expect(_types(platform), <String>[
        'page:100',
        'page:101',
        'page:104',
        'page:300',
      ]);
    });

    testWidgets('follow the saved favourites, not the built-in ones', (
      WidgetTester tester,
    ) async {
      await service.start();
      await _open(
        tester,
        shortcuts: service,
        saved: const SavedPages(
          favourites: <Favourite>[Favourite(377), Favourite(450, 'EKONOMI')],
        ),
      );

      expect(_types(platform), <String>['page:377', 'page:450']);
      expect(platform.current.last.title, '450 EKONOMI');
    });

    testWidgets('change when a page is starred', (WidgetTester tester) async {
      await service.start();
      await _open(
        tester,
        shortcuts: service,
        start: 377,
        saved: const SavedPages(favourites: <Favourite>[Favourite(100)]),
      );
      expect(_types(platform), <String>['page:100']);

      await tester.tap(find.byKey(textTvStarKey));
      await tester.pumpAndSettle();

      expect(_types(platform), <String>['page:100', 'page:377']);
    });

    testWidgets('change when a favourite is removed', (
      WidgetTester tester,
    ) async {
      await service.start();
      await _open(tester, shortcuts: service, start: 101);

      await tester.tap(find.byKey(textTvStarKey));
      await tester.pumpAndSettle();

      expect(_types(platform), <String>[
        'page:100',
        'page:104',
        'page:300',
        'page:400',
      ]);
    });

    testWidgets('are not told again for a page read, only for a change', (
      WidgetTester tester,
    ) async {
      await service.start();
      await _open(tester, shortcuts: service);
      final int before = platform.sets.length;

      await tester.tap(find.byKey(textTvNextKey));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(textTvNextKey));
      await tester.pumpAndSettle();

      expect(platform.sets, hasLength(before));
    });

    testWidgets('are emptied when the last favourite goes', (
      WidgetTester tester,
    ) async {
      await service.start();
      await _open(
        tester,
        shortcuts: service,
        start: 377,
        saved: const SavedPages(favourites: <Favourite>[Favourite(377)]),
      );

      await tester.tap(find.byKey(textTvStarKey));
      await tester.pumpAndSettle();

      expect(platform.current, isEmpty);
    });

    testWidgets('a phone that cannot do shortcuts changes nothing', (
      WidgetTester tester,
    ) async {
      platform.failing = true;
      await service.start();
      await _open(tester, shortcuts: service, start: 377);

      await tester.tap(find.byKey(textTvStarKey));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byKey(textTvChipKey(377)), findsOneWidget);
    });

    testWidgets('the viewer works with no shortcut service at all', (
      WidgetTester tester,
    ) async {
      await _open(tester, shortcuts: null);

      expect(find.byKey(textTvChipKey(100)), findsOneWidget);
    });
  });

  group('choosing a shortcut', () {
    testWidgets('while the app runs opens that page', (
      WidgetTester tester,
    ) async {
      final FakeTextTvRepository repository = _repository();
      await service.start();
      await _open(tester, shortcuts: service, repository: repository);

      platform.choose('page:377');
      await tester.pumpAndSettle();

      expect(_number('377'), findsOneWidget);
      expect(repository.requests.last, (377, false));
    });

    testWidgets('the page it left is where back goes', (
      WidgetTester tester,
    ) async {
      await service.start();
      await _open(tester, shortcuts: service);

      platform.choose('page:377');
      await tester.pumpAndSettle();
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();

      expect(_number('100'), findsOneWidget);
    });

    testWidgets(
      'one that started the app is opened as soon as the screen is up',
      (WidgetTester tester) async {
        await service.start();
        // The icon was pressed before there was a screen to listen.
        platform.choose('page:450');

        await _open(tester, shortcuts: service);
        await tester.pumpAndSettle();

        expect(_number('450'), findsOneWidget);
      },
    );

    testWidgets('one that is not a page of ours does nothing', (
      WidgetTester tester,
    ) async {
      await service.start();
      await _open(tester, shortcuts: service);

      platform.choose('page:99');
      platform.choose('whatever');
      await tester.pumpAndSettle();

      expect(_number('100'), findsOneWidget);
    });

    testWidgets('one choice after another opens each', (
      WidgetTester tester,
    ) async {
      await service.start();
      await _open(tester, shortcuts: service);

      platform.choose('page:300');
      await tester.pumpAndSettle();
      platform.choose('page:400');
      await tester.pumpAndSettle();

      expect(_number('400'), findsOneWidget);
    });

    testWidgets('a page chosen is remembered among the recent ones', (
      WidgetTester tester,
    ) async {
      final List<SavedPages> heard = <SavedPages>[];
      await service.start();
      tester.view
        ..physicalSize = const Size(800, 2400)
        ..devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp(
          theme: textTvTheme(),
          home: TextTvScreen(
            repository: _repository(),
            shortcuts: service,
            onSavedChanged: heard.add,
          ),
        ),
      );
      await tester.pumpAndSettle();

      platform.choose('page:377');
      await tester.pumpAndSettle();

      expect(heard.last.recents.first, 377);
    });
  });
}
