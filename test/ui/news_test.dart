import 'package:codedbykay_text_tv/model/controls_settings.dart';
import 'package:codedbykay_text_tv/model/feed.dart';
import 'package:codedbykay_text_tv/model/text_tv_page.dart';
import 'package:codedbykay_text_tv/ui/text_tv_keys.dart';
import 'package:codedbykay_text_tv/ui/text_tv_screen.dart';
import 'package:codedbykay_text_tv/ui/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fakes/english.dart';
import '../fakes/fake_text_tv_repository.dart';

FakeTextTvRepository _repository() {
  final FakeTextTvRepository r = FakeTextTvRepository(<int, TextTvPage>{
    for (int n = 100; n <= 799; n++)
      n: TextTvPage(
        number: n,
        parts: <List<String>>[
          <String>['$n SVT Text', 'Sida $n'],
        ],
        previous: n - 1,
        next: n + 1,
      ),
  });
  r.feeds[FeedKind.latestNews] = const <FeedItem>[
    FeedItem(138, 'Skolor stänger efter protester', '12:06'),
    FeedItem(106, 'Trio får Nobelpriset i medicin', '11:56'),
  ];
  r.feeds[FeedKind.latestSport] = const <FeedItem>[
    FeedItem(377, 'Fotboll Nations League', '11:44'),
  ];
  r.feeds[FeedKind.mostRead] = const <FeedItem>[];
  return r;
}

Future<FakeTextTvRepository> _open(
  WidgetTester tester, {
  ControlsSettings controls = ControlsSettings.defaults,
}) async {
  tester.view
    ..physicalSize = const Size(800, 2400)
    ..devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final FakeTextTvRepository repository = _repository();
  await tester.pumpWidget(
    MaterialApp(
      theme: textTvTheme(),
      home: TextTvScreen(repository: repository, controls: controls),
    ),
  );
  await tester.pumpAndSettle();
  return repository;
}

Future<void> _openNews(WidgetTester tester) async {
  await tester.tap(find.byKey(textTvNewsKey));
  await tester.pumpAndSettle();
}

Finder _number(String text) =>
    find.descendant(of: find.byKey(textTvNumberKey), matching: find.text(text));

void main() {
  group('what is new', () {
    testWidgets(
      'has a button after the history one, named for a screen reader',
      (WidgetTester tester) async {
        final SemanticsHandle handle = tester.ensureSemantics();
        await _open(tester);

        expect(find.byKey(textTvNewsKey), findsOneWidget);
        expect(find.bySemanticsLabel(en.newsLabel), findsOneWidget);
        expect(
          tester.getTopLeft(find.byKey(textTvNewsKey)).dx,
          greaterThan(tester.getTopLeft(find.byKey(textTvRecentsKey)).dx),
        );
        handle.dispose();
      },
    );

    testWidgets('is there with the always-on number pad too', (
      WidgetTester tester,
    ) async {
      await _open(tester, controls: const ControlsSettings(quickEntry: true));

      expect(find.byKey(textTvNewsKey), findsOneWidget);
    });

    testWidgets('opens on the latest news, asking the site for just that', (
      WidgetTester tester,
    ) async {
      final FakeTextTvRepository repository = await _open(tester);

      await _openNews(tester);

      expect(find.text(en.newsTitle), findsOneWidget);
      expect(repository.feedRequests, <FeedKind>[FeedKind.latestNews]);
      expect(find.byKey(textTvFeedItemKey(138)), findsOneWidget);
      expect(find.text('Skolor stänger efter protester'), findsOneWidget);
      expect(find.text('12:06'), findsOneWidget);
    });

    testWidgets('a line opens its page', (WidgetTester tester) async {
      await _open(tester);
      await _openNews(tester);

      await tester.tap(find.byKey(textTvFeedItemKey(106)));
      await tester.pumpAndSettle();

      expect(_number('106'), findsOneWidget);
      expect(find.text(en.newsTitle), findsNothing, reason: 'sheet shut');
    });

    testWidgets('another list is asked for when it is chosen, not before', (
      WidgetTester tester,
    ) async {
      final FakeTextTvRepository repository = await _open(tester);
      await _openNews(tester);

      await tester.tap(find.byKey(textTvFeedKindKey(FeedKind.latestSport)));
      await tester.pumpAndSettle();

      expect(repository.feedRequests, <FeedKind>[
        FeedKind.latestNews,
        FeedKind.latestSport,
      ]);
      expect(find.byKey(textTvFeedItemKey(377)), findsOneWidget);
      expect(find.byKey(textTvFeedItemKey(138)), findsNothing);
    });

    testWidgets('choosing the list already shown asks for nothing', (
      WidgetTester tester,
    ) async {
      final FakeTextTvRepository repository = await _open(tester);
      await _openNews(tester);

      await tester.tap(find.byKey(textTvFeedKindKey(FeedKind.latestNews)));
      await tester.pumpAndSettle();

      expect(repository.feedRequests, hasLength(1));
    });

    testWidgets('a list with nothing in it says so', (
      WidgetTester tester,
    ) async {
      await _open(tester);
      await _openNews(tester);

      await tester.tap(find.byKey(textTvFeedKindKey(FeedKind.mostRead)));
      await tester.pumpAndSettle();

      expect(find.byKey(textTvFeedEmptyKey), findsOneWidget);
      expect(find.text(en.feedEmpty), findsOneWidget);
    });

    testWidgets(
      'a list that could not be read says so, and can be tried again',
      (WidgetTester tester) async {
        final FakeTextTvRepository repository = await _open(tester);
        repository.feeds.remove(FeedKind.latestNews);
        await _openNews(tester);

        expect(find.byKey(textTvFeedFailedKey), findsOneWidget);

        repository.feeds[FeedKind.latestNews] = const <FeedItem>[
          FeedItem(138, 'Åter', null),
        ];
        await tester.tap(find.byKey(textTvRetryKey));
        await tester.pumpAndSettle();

        expect(find.byKey(textTvFeedFailedKey), findsNothing);
        expect(find.text('Åter'), findsOneWidget);
      },
    );

    testWidgets('a line with no time shows none, and still reads aloud', (
      WidgetTester tester,
    ) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      final FakeTextTvRepository repository = await _open(tester);
      repository.feeds[FeedKind.latestNews] = const <FeedItem>[
        FeedItem(138, 'Utan tid'),
      ];
      await _openNews(tester);

      expect(
        find.bySemanticsLabel('Utan tid. ${en.pageLabel(138)}'),
        findsOneWidget,
      );
      handle.dispose();
    });
  });
}
