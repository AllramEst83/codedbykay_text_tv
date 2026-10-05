import 'dart:io';

import 'package:codedbykay_text_tv/messages.dart';
import 'package:codedbykay_text_tv/model/reader_settings.dart';
import 'package:codedbykay_text_tv/model/text_tv_page.dart';
import 'package:codedbykay_text_tv/services/text_tv.dart';
import 'package:codedbykay_text_tv/ui/text_tv_keys.dart';
import 'package:codedbykay_text_tv/ui/text_tv_screen.dart';
import 'package:codedbykay_text_tv/ui/theme.dart';
import 'package:codedbykay_text_tv/ui/tv_row.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fakes/fake_http_fetcher.dart';
import '../fakes/fake_text_tv_repository.dart';

TextTvPage _fixture(int number) => TextTv(
  fetcher: FakeHttpFetcher(),
).parse(number, File('test/fixtures/texttv_$number.json').readAsStringSync())!;

TextTvPage _simple(int number, {List<List<String>>? parts}) => TextTvPage(
  number: number,
  parts:
      parts ??
      <List<String>>[
        <String>['$number SVT Text', '', 'Sida $number'],
      ],
);

FakeTextTvRepository _repository() => FakeTextTvRepository(<int, TextTvPage>{
  100: _fixture(100),
  101: _simple(101),
  107: _simple(107),
  130: _simple(130),
  377: _fixture(377),
});

Future<void> _open(
  WidgetTester tester,
  FakeTextTvRepository repository, {
  ReaderSettings reader = const ReaderSettings(enabled: true),
  ValueChanged<ReaderSettings>? onReaderChanged,
}) async {
  tester.view
    ..physicalSize = const Size(800, 4000)
    ..devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      theme: textTvTheme(),
      home: TextTvScreen(
        repository: repository,
        reader: reader,
        onReaderChanged: onReaderChanged,
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Finder _text(String text) => find.textContaining(text, findRichText: true);

Finder _number(String text) =>
    find.descendant(of: find.byKey(textTvNumberKey), matching: find.text(text));

/// The colour the reader gave the text of the paragraph containing [text].
Color? _colourOf(WidgetTester tester, String text) {
  final RenderParagraph paragraph = tester.renderObject<RenderParagraph>(
    _text(text),
  );
  final TextSpan root = paragraph.text as TextSpan;
  return (root.children!.first as TextSpan).style?.color;
}

Color _background(WidgetTester tester) =>
    tester.widget<ColoredBox>(find.byKey(textTvReaderViewKey)).color;

bool _enabled(WidgetTester tester, Key key) =>
    tester
        .widget<InkWell>(
          find.descendant(of: find.byKey(key), matching: find.byType(InkWell)),
        )
        .onTap !=
    null;

void main() {
  group('the glasses button', () {
    testWidgets('starts on the teletext page', (WidgetTester tester) async {
      await _open(tester, _repository(), reader: const ReaderSettings());

      expect(find.byType(TvRow), findsWidgets);
      expect(find.byKey(textTvReaderViewKey), findsNothing);
      expect(find.byKey(textTvReaderSmallerKey), findsNothing);
    });

    testWidgets('switches to reader mode and back', (
      WidgetTester tester,
    ) async {
      await _open(tester, _repository(), reader: const ReaderSettings());

      await tester.tap(find.byKey(textTvReaderKey));
      await tester.pumpAndSettle();
      expect(find.byKey(textTvReaderViewKey), findsOneWidget);
      expect(find.byType(TvRow), findsNothing);
      expect(find.byKey(textTvReaderLargerKey), findsOneWidget);

      await tester.tap(find.byKey(textTvReaderKey));
      await tester.pumpAndSettle();
      expect(find.byKey(textTvReaderViewKey), findsNothing);
      expect(find.byType(TvRow), findsWidgets);
    });

    testWidgets('says what it will do, for a screen reader', (
      WidgetTester tester,
    ) async {
      await _open(tester, _repository(), reader: const ReaderSettings());
      expect(find.bySemanticsLabel(Messages.readerOn), findsOneWidget);

      await tester.tap(find.byKey(textTvReaderKey));
      await tester.pumpAndSettle();

      expect(find.bySemanticsLabel(Messages.readerOff), findsOneWidget);
    });
  });

  group('the reader bar', () {
    testWidgets('leaves a gap between its buttons and the page', (
      WidgetTester tester,
    ) async {
      await _open(tester, _repository());

      final double buttonsBottom = tester
          .getBottomLeft(find.byKey(textTvReaderLargerKey))
          .dy;
      final double pageTop = tester
          .getTopLeft(find.byKey(textTvReaderViewKey))
          .dy;

      expect(pageTop - buttonsBottom, greaterThanOrEqualTo(TvMetrics.margin));
    });

    testWidgets('A- and A+ are the same square as the glasses button', (
      WidgetTester tester,
    ) async {
      await _open(tester, _repository());

      final Size glasses = tester.getSize(find.byKey(textTvReaderKey));
      expect(tester.getSize(find.byKey(textTvReaderSmallerKey)), glasses);
      expect(tester.getSize(find.byKey(textTvReaderLargerKey)), glasses);
    });
  });

  group('reading', () {
    testWidgets('shows the page as text, headlines and all', (
      WidgetTester tester,
    ) async {
      await _open(tester, _repository());

      expect(find.byType(TvRow), findsNothing);
      expect(_text('Akilov i avskildhet efter två slagsmål'), findsOneWidget);
      expect(_text('Incidenter i fängelset med terroristen'), findsOneWidget);
      expect(_text('Inrikes 101'), findsOneWidget);
    });

    testWidgets('a story with a page number opens that page when tapped', (
      WidgetTester tester,
    ) async {
      final FakeTextTvRepository repository = _repository();
      await _open(tester, repository);

      await tester.tap(_text('Incidenter i fängelset med terroristen'));
      await tester.pumpAndSettle();

      expect(_number('107'), findsOneWidget);
      expect(repository.requests.last, (107, false));
    });

    testWidgets('a link-row chip opens its page', (WidgetTester tester) async {
      await _open(tester, _repository());

      await tester.tap(_text('Inrikes 101'));
      await tester.pumpAndSettle();

      expect(_number('101'), findsOneWidget);
    });

    testWidgets('a score table keeps its two columns', (
      WidgetTester tester,
    ) async {
      final FakeTextTvRepository repository = _repository();
      await _open(
        tester,
        repository,
        reader: const ReaderSettings(enabled: true),
      );
      await tester.tap(_text('Inrikes 101'));
      await tester.pumpAndSettle();
      repository.pages[101] = _fixture(377);
      await tester.tap(find.byKey(textTvRefreshKey));
      await tester.pumpAndSettle();

      final Offset team = tester.getTopLeft(_text('Kristianstad - Vittsjö'));
      final Offset score = tester.getTopLeft(_text('0 - 1 13:00'));
      expect(score.dx, greaterThan(team.dx + 100));
      expect(score.dy, closeTo(team.dy, 2));
    });

    testWidgets('a swipe still turns the part', (WidgetTester tester) async {
      final FakeTextTvRepository repository = _repository();
      repository.pages[101] = _simple(
        101,
        parts: <List<String>>[
          <String>['101 SVT Text', '', 'Första delen'],
          <String>['101 SVT Text', '', 'Andra delen'],
        ],
      );
      await _open(tester, repository);
      await tester.tap(_text('Inrikes 101'));
      await tester.pumpAndSettle();
      expect(_text('Första delen'), findsOneWidget);

      await tester.fling(
        find.byKey(textTvReaderViewKey),
        const Offset(-300, 0),
        1000,
      );
      await tester.pumpAndSettle();

      expect(_text('Andra delen'), findsOneWidget);
    });

    testWidgets('says so when the page is loading, missing or failed', (
      WidgetTester tester,
    ) async {
      final FakeTextTvRepository repository = _repository();
      repository.failure = const TextTvFailed('No signal');
      await _open(tester, repository);

      expect(_text('No signal'), findsOneWidget);
      expect(find.byKey(textTvRetryKey), findsOneWidget);

      repository.failure = null;
      await tester.tap(find.byKey(textTvRetryKey));
      await tester.pumpAndSettle();
      expect(_text('Akilov'), findsOneWidget);
      expect(repository.requests.last, (100, true));
    });

    testWidgets('a page not in broadcast says so', (WidgetTester tester) async {
      final FakeTextTvRepository repository = _repository();
      repository.pages.remove(101);
      await _open(tester, repository);

      await tester.tap(find.byKey(textTvNextKey));
      await tester.pumpAndSettle();

      expect(_text(Messages.readerNotBroadcast(101)), findsOneWidget);
      expect(find.byKey(textTvReaderViewKey), findsOneWidget);
    });

    testWidgets('back works as it does on the teletext page', (
      WidgetTester tester,
    ) async {
      await _open(tester, _repository());
      await tester.tap(_text('Inrikes 101'));
      await tester.pumpAndSettle();
      expect(_number('101'), findsOneWidget);

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();

      expect(_number('100'), findsOneWidget);
      expect(_text('Akilov'), findsOneWidget);
    });
  });

  group('text size', () {
    // The caption is one short line at every size, so its height follows the
    // font size alone.
    double height(WidgetTester tester) =>
        tester.getSize(_text('100 SVT Text')).height;

    testWidgets('A+ makes the text larger, A- smaller', (
      WidgetTester tester,
    ) async {
      await _open(tester, _repository());
      final double normal = height(tester);

      await tester.tap(find.byKey(textTvReaderLargerKey));
      await tester.pumpAndSettle();
      final double larger = height(tester);
      expect(larger, greaterThan(normal));

      await tester.tap(find.byKey(textTvReaderSmallerKey));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(textTvReaderSmallerKey));
      await tester.pumpAndSettle();
      expect(height(tester), lessThan(normal));
    });

    testWidgets('stops at the smallest and the largest', (
      WidgetTester tester,
    ) async {
      await _open(
        tester,
        _repository(),
        reader: const ReaderSettings(enabled: true, size: 0),
      );
      expect(_enabled(tester, textTvReaderSmallerKey), isFalse);
      expect(_enabled(tester, textTvReaderLargerKey), isTrue);

      await _open(
        tester,
        _repository(),
        reader: ReaderSettings(enabled: true, size: readerTextSizes.length - 1),
      );
      await tester.pumpWidget(const SizedBox());
      await _open(
        tester,
        _repository(),
        reader: ReaderSettings(enabled: true, size: readerTextSizes.length - 1),
      );
      expect(_enabled(tester, textTvReaderLargerKey), isFalse);
      expect(_enabled(tester, textTvReaderSmallerKey), isTrue);
    });
  });

  group('colours', () {
    testWidgets('each swatch sets the reader background', (
      WidgetTester tester,
    ) async {
      await _open(tester, _repository());

      for (final ReaderTheme theme in ReaderTheme.values) {
        await tester.tap(find.byKey(textTvReaderThemeKey(theme)));
        await tester.pumpAndSettle();

        expect(_background(tester), readerPalette(theme).background);
      }
    });

    testWidgets('the text takes the theme colour', (WidgetTester tester) async {
      await _open(
        tester,
        _repository(),
        reader: const ReaderSettings(enabled: true, theme: ReaderTheme.beige),
      );

      expect(
        _colourOf(tester, 'Incidenter'),
        readerPalette(ReaderTheme.beige).text,
      );
      expect(_background(tester), readerPalette(ReaderTheme.beige).background);
    });

    testWidgets('the readable schemes have real contrast', (
      WidgetTester tester,
    ) async {
      for (final ReaderTheme theme in ReaderTheme.values) {
        final ReaderPalette p = readerPalette(theme);
        double contrast(Color a, Color b) {
          final double la = a.computeLuminance() + 0.05;
          final double lb = b.computeLuminance() + 0.05;
          return la > lb ? la / lb : lb / la;
        }

        expect(
          contrast(p.text, p.background),
          greaterThan(7),
          reason: '$theme',
        );
        expect(
          contrast(p.link, p.background),
          greaterThan(4.5),
          reason: '$theme',
        );
        expect(
          contrast(p.dim, p.background),
          greaterThan(4.5),
          reason: '$theme',
        );
      }
    });
  });

  group('remembering', () {
    testWidgets('reports every change', (WidgetTester tester) async {
      final List<ReaderSettings> heard = <ReaderSettings>[];
      await _open(
        tester,
        _repository(),
        reader: const ReaderSettings(),
        onReaderChanged: heard.add,
      );

      await tester.tap(find.byKey(textTvReaderKey));
      await tester.pumpAndSettle();
      expect(heard.last, const ReaderSettings(enabled: true));

      await tester.tap(find.byKey(textTvReaderThemeKey(ReaderTheme.paper)));
      await tester.pumpAndSettle();
      expect(heard.last.theme, ReaderTheme.paper);

      await tester.tap(find.byKey(textTvReaderLargerKey));
      await tester.pumpAndSettle();
      expect(heard.last.size, readerDefaultSize + 1);
      expect(heard.last.enabled, isTrue);
    });

    testWidgets('opens in reader mode with the saved look', (
      WidgetTester tester,
    ) async {
      await _open(
        tester,
        _repository(),
        reader: const ReaderSettings(
          enabled: true,
          theme: ReaderTheme.grey,
          size: 4,
        ),
      );

      expect(find.byType(TvRow), findsNothing);
      expect(_background(tester), readerPalette(ReaderTheme.grey).background);
    });
  });
}
