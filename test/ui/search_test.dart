import 'package:codedbykay_text_tv/model/text_tv_page.dart';
import 'package:codedbykay_text_tv/ui/text_tv_keys.dart';
import 'package:codedbykay_text_tv/ui/text_tv_screen.dart';
import 'package:codedbykay_text_tv/ui/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fakes/fake_text_tv_repository.dart';

TextTvPage _page(int n, String line) => TextTvPage(
  number: n,
  parts: <List<String>>[
    <String>['$n SVT Text', line],
  ],
  previous: n - 1,
  next: n + 1,
);

FakeTextTvRepository _repository() => FakeTextTvRepository(<int, TextTvPage>{
  100: _page(100, 'Hej'),
  130: _page(130, 'Skåne får snö'),
  300: _page(300, 'Fotboll: AIK vinner'),
  377: _page(377, 'Snö i Norrland'),
});

Future<FakeTextTvRepository> _open(WidgetTester tester) async {
  tester.view
    ..physicalSize = const Size(800, 2400)
    ..devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final FakeTextTvRepository repository = _repository();
  await tester.pumpWidget(
    MaterialApp(
      theme: textTvTheme(),
      home: TextTvScreen(repository: repository),
    ),
  );
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(textTvSearchKey));
  await tester.pumpAndSettle();
  return repository;
}

Future<void> _type(WidgetTester tester, String text) async {
  await tester.enterText(find.byKey(textTvSearchFieldKey), text);
  // Past the wait before a search starts.
  await tester.pump(const Duration(milliseconds: 300));
  await tester.pump();
}

Finder _number(String text) =>
    find.descendant(of: find.byKey(textTvNumberKey), matching: find.text(text));

void main() {
  testWidgets('on a narrow phone the whole top bar fits, title and all', (
    WidgetTester tester,
  ) async {
    tester.view
      ..physicalSize = const Size(360, 800)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        theme: textTvTheme(),
        home: TextTvScreen(repository: _repository()),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('TEXT TV'), findsOneWidget);
    final Rect title = tester.getRect(find.text('TEXT TV'));
    final Rect search = tester.getRect(find.byKey(textTvSearchKey));
    expect(title.right, lessThanOrEqualTo(search.left));
  });

  group('the search', () {
    testWidgets('a word lists the pages that have it', (
      WidgetTester tester,
    ) async {
      await _open(tester);

      await _type(tester, 'snö');

      expect(find.byKey(textTvSearchHitKey(130)), findsOneWidget);
      expect(find.byKey(textTvSearchHitKey(377)), findsOneWidget);
      expect(find.byKey(textTvSearchHitKey(300)), findsNothing);
    });

    testWidgets('choosing a hit opens that page', (WidgetTester tester) async {
      await _open(tester);
      await _type(tester, 'fotboll');

      await tester.tap(find.byKey(textTvSearchHitKey(300)));
      await tester.pumpAndSettle();

      expect(_number('300'), findsOneWidget);
      expect(find.byKey(textTvSearchFieldKey), findsNothing);
    });

    testWidgets('a page number offers going straight there', (
      WidgetTester tester,
    ) async {
      await _open(tester);

      await _type(tester, '377');
      await tester.tap(find.byKey(textTvSearchGoKey));
      await tester.pumpAndSettle();

      expect(_number('377'), findsOneWidget);
    });

    testWidgets('a number that is not a page offers nothing to go to', (
      WidgetTester tester,
    ) async {
      await _open(tester);

      await _type(tester, '999');

      expect(find.byKey(textTvSearchGoKey), findsNothing);
      expect(find.byKey(textTvSearchEmptyKey), findsOneWidget);
    });

    testWidgets('a word nothing has says so', (WidgetTester tester) async {
      await _open(tester);

      await _type(tester, 'zebra');

      expect(find.byKey(textTvSearchEmptyKey), findsOneWidget);
    });

    testWidgets('a single letter is not searched', (WidgetTester tester) async {
      final FakeTextTvRepository repository = await _open(tester);

      await _type(tester, 's');

      expect(repository.searches, isEmpty);
      expect(find.byKey(textTvSearchEmptyKey), findsNothing);
    });

    testWidgets('search waits for a pause in the typing', (
      WidgetTester tester,
    ) async {
      final FakeTextTvRepository repository = await _open(tester);

      await tester.enterText(find.byKey(textTvSearchFieldKey), 'sn');
      await tester.pump(const Duration(milliseconds: 100));
      await tester.enterText(find.byKey(textTvSearchFieldKey), 'snö');
      await tester.pump(const Duration(milliseconds: 300));

      expect(repository.searches, <String>['snö']);
    });

    testWidgets('the keyboard\'s search key opens the best hit', (
      WidgetTester tester,
    ) async {
      await _open(tester);
      await _type(tester, 'fotboll');

      await tester.testTextInput.receiveAction(TextInputAction.search);
      await tester.pumpAndSettle();

      expect(_number('300'), findsOneWidget);
    });
  });
}
