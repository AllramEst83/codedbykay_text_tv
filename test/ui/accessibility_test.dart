import 'dart:io';

import 'package:codedbykay_text_tv/model/reader_settings.dart';
import 'package:codedbykay_text_tv/model/text_tv_page.dart';
import 'package:codedbykay_text_tv/services/text_tv.dart';
import 'package:codedbykay_text_tv/ui/text_tv_screen.dart';
import 'package:codedbykay_text_tv/ui/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fakes/english.dart';
import '../fakes/fake_http_fetcher.dart';
import '../fakes/fake_text_tv_repository.dart';

TextTvPage _fixture(int n) =>
    TextTv(fetcher: FakeHttpFetcher())
        .parse(n, File('test/fixtures/texttv_$n.json').readAsStringSync())!;

Future<FakeTextTvRepository> _open(
  WidgetTester tester, {
  ReaderSettings reader = const ReaderSettings(),
  Map<int, TextTvPage>? pages,
}) async {
  tester.view
    ..physicalSize = const Size(800, 4000)
    ..devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final FakeTextTvRepository repository = FakeTextTvRepository(
    pages ?? <int, TextTvPage>{100: _fixture(100), 104: _fixture(104)},
  );
  await tester.pumpWidget(
    MaterialApp(
      theme: textTvTheme(),
      home: TextTvScreen(repository: repository, reader: reader),
    ),
  );
  await tester.pumpAndSettle();
  return repository;
}

void main() {
  group('the page, for a screen reader', () {
    testWidgets('has a label of its own: its number', (
      WidgetTester tester,
    ) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await _open(tester);

      expect(find.bySemanticsLabel(en.pageLabel(100)), findsWidgets);
      handle.dispose();
    });

    testWidgets('says which part of several is on show', (
      WidgetTester tester,
    ) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await _open(
        tester,
        pages: <int, TextTvPage>{
          100: const TextTvPage(
            number: 100,
            parts: <List<String>>[
              <String>['100 SVT Text', 'Ett'],
              <String>['100 SVT Text', 'Två'],
            ],
          ),
        },
      );

      expect(find.bySemanticsLabel(en.pageAndPart(100, 1, 2)), findsOneWidget);
      handle.dispose();
    });

    testWidgets('is announced when it changes: a live region', (
      WidgetTester tester,
    ) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await _open(tester);

      final SemanticsNode node = tester.getSemantics(
        find.bySemanticsLabel(en.pageLabel(100)).first,
      );
      expect(node.getSemanticsData().flagsCollection.isLiveRegion, isTrue);
      handle.dispose();
    });

    testWidgets('has its page links as buttons TalkBack can reach', (
      WidgetTester tester,
    ) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await _open(tester);

      // Page 100 links to other pages; each is a button named by its page.
      expect(find.semantics.byFlag(SemanticsFlag.isButton), findsWidgets);
      expect(find.semantics.byLabel(en.pageLabel(104)), findsWidgets);
      handle.dispose();
    });

    testWidgets('a link is opened by its accessibility tap', (
      WidgetTester tester,
    ) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      final FakeTextTvRepository repository = await _open(tester);
      repository.requests.clear();

      // The first link on the page that is a plain page number.
      final SemanticsFinder link = find.semantics.byPredicate(
        (SemanticsNode n) =>
            n.label == en.pageLabel(104) &&
            n.getSemanticsData().flagsCollection.isButton,
      );
      expect(link, findsWidgets);
      tester.semantics.tap(link.first);
      await tester.pumpAndSettle();

      expect(repository.requests.first.$1, 104);
      handle.dispose();
    });

    testWidgets('reader mode says its page too', (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await _open(tester, reader: const ReaderSettings(enabled: true));

      expect(find.bySemanticsLabel(en.pageLabel(100)), findsWidgets);
      handle.dispose();
    });

    testWidgets('the rows still read as their text', (
      WidgetTester tester,
    ) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await _open(tester);

      expect(find.bySemanticsLabel(RegExp('SVT Text')), findsWidgets);
      handle.dispose();
    });
  });
}
