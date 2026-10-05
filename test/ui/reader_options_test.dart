import 'dart:io';

import 'package:codedbykay_text_tv/model/reader_settings.dart';
import 'package:codedbykay_text_tv/model/text_tv_page.dart';
import 'package:codedbykay_text_tv/services/text_tv.dart';
import 'package:codedbykay_text_tv/ui/formats.dart';
import 'package:codedbykay_text_tv/ui/text_tv_keys.dart';
import 'package:codedbykay_text_tv/ui/text_tv_screen.dart';
import 'package:codedbykay_text_tv/ui/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fakes/english.dart';
import '../fakes/fake_http_fetcher.dart';
import '../fakes/fake_text_tv_repository.dart';

/// The reader's column is at most 680 wide and centred, so on the 800-wide
/// screen used here its left edge is 60.
const double _columnLeft = 60;

Future<void> _open(
  WidgetTester tester, {
  ReaderSettings reader = const ReaderSettings(enabled: true),
  ValueChanged<ReaderSettings>? onReaderChanged,
}) async {
  tester.view
    ..physicalSize = const Size(800, 4000)
    ..devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final TextTvPage page = TextTv(fetcher: FakeHttpFetcher())
      .parse(100, File('test/fixtures/texttv_100.json').readAsStringSync())!;
  await tester.pumpWidget(
    MaterialApp(
      theme: textTvTheme(),
      home: TextTvScreen(
        repository: FakeTextTvRepository(<int, TextTvPage>{100: page}),
        reader: reader,
        onReaderChanged: onReaderChanged,
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _openOptions(WidgetTester tester) async {
  await tester.tap(find.byKey(textTvReaderOptionsKey));
  await tester.pumpAndSettle();
}

Finder _text(String text) => find.textContaining(text, findRichText: true);

/// Drags slider [key] to its far end ([toEnd]) or its start.
Future<void> _drag(WidgetTester tester, Key key, {required bool toEnd}) async {
  await tester.drag(find.byKey(key), Offset(toEnd ? 3000 : -3000, 0));
  await tester.pumpAndSettle();
}

/// The weight of the text of the paragraph containing [text].
FontWeight? _weight(WidgetTester tester, String text) {
  final RenderParagraph p = tester.renderObject<RenderParagraph>(_text(text));
  return ((p.text as TextSpan).children!.first as TextSpan).style?.fontWeight;
}

String? _family(WidgetTester tester, String text) {
  final RenderParagraph p = tester.renderObject<RenderParagraph>(_text(text));
  return ((p.text as TextSpan).children!.first as TextSpan).style?.fontFamily;
}

void main() {
  group('the typeface', () {
    testWidgets('the reader starts in the system font', (
      WidgetTester tester,
    ) async {
      await _open(tester);

      expect(_family(tester, 'Incidenter'), 'Roboto');
    });

    testWidgets('a saved choice is used', (WidgetTester tester) async {
      await _open(
        tester,
        reader: const ReaderSettings(enabled: true, font: ReaderFont.dyslexic),
      );

      expect(_family(tester, 'Incidenter'), 'OpenDyslexic');
    });

    testWidgets('the options offer the three, each named in itself', (
      WidgetTester tester,
    ) async {
      await _open(
        tester,
        reader: const ReaderSettings(enabled: true, font: ReaderFont.atkinson),
      );
      await _openOptions(tester);

      for (final ReaderFont font in ReaderFont.values) {
        expect(find.byKey(textTvReaderFontKey(font)), findsOneWidget);
      }
      expect(find.text('ATKINSON'), findsOneWidget);
      expect(find.text('OPENDYSLEXIC'), findsOneWidget);
    });

    testWidgets('choosing one sets the text in it at once, and says so', (
      WidgetTester tester,
    ) async {
      final List<ReaderSettings> heard = <ReaderSettings>[];
      await _open(tester, onReaderChanged: heard.add);
      await _openOptions(tester);

      await tester.tap(find.byKey(textTvReaderFontKey(ReaderFont.atkinson)));
      await tester.pumpAndSettle();

      expect(heard.last.font, ReaderFont.atkinson);
      expect(_family(tester, 'Incidenter'), 'AtkinsonHyperlegible');
    });

    testWidgets('and back to the system font', (WidgetTester tester) async {
      await _open(
        tester,
        reader: const ReaderSettings(enabled: true, font: ReaderFont.dyslexic),
      );
      await _openOptions(tester);

      await tester.tap(find.byKey(textTvReaderFontKey(ReaderFont.system)));
      await tester.pumpAndSettle();

      expect(_family(tester, 'Incidenter'), 'Roboto');
    });

    testWidgets('RESET leaves the chosen typeface', (
      WidgetTester tester,
    ) async {
      final List<ReaderSettings> heard = <ReaderSettings>[];
      await _open(
        tester,
        reader: const ReaderSettings(enabled: true, font: ReaderFont.dyslexic),
        onReaderChanged: heard.add,
      );
      await _openOptions(tester);

      await tester.tap(find.byKey(textTvReaderResetKey));
      await tester.pumpAndSettle();

      expect(heard.last.font, ReaderFont.dyslexic);
    });
  });

  group('the options button', () {
    testWidgets('opens the options over the page', (WidgetTester tester) async {
      await _open(tester);
      expect(find.text(en.readerOptionsTitle), findsNothing);

      await _openOptions(tester);

      expect(find.text(en.readerOptionsTitle), findsOneWidget);
      expect(find.byKey(textTvReaderLineKey), findsOneWidget);
      expect(find.byKey(textTvReaderLetterKey), findsOneWidget);
      expect(find.byKey(textTvReaderMarginKey), findsOneWidget);
      expect(find.byKey(textTvReaderBoldKey), findsOneWidget);
    });

    testWidgets('has a name for a screen reader', (WidgetTester tester) async {
      await _open(tester);

      expect(find.bySemanticsLabel(en.readerOptions), findsOneWidget);
    });

    testWidgets('is only there in reader mode', (WidgetTester tester) async {
      await _open(tester, reader: const ReaderSettings());

      expect(find.byKey(textTvReaderOptionsKey), findsNothing);
    });

    testWidgets('shows what is set now', (WidgetTester tester) async {
      await _open(
        tester,
        reader: const ReaderSettings(
          enabled: true,
          lineSpacing: 4,
          letterSpacing: 3,
          margin: 0,
          bold: true,
        ),
      );
      await _openOptions(tester);

      expect(find.text(Formats.times(2.0)), findsOneWidget);
      expect(find.text(Formats.percent(0.1)), findsOneWidget);
      expect(find.text(Formats.logicalPixels(12)), findsOneWidget);
      expect(
        tester.widget<Switch>(find.byKey(textTvReaderBoldKey)).value,
        isTrue,
      );
    });
  });

  group('the text follows the options', () {
    double captionHeight(WidgetTester tester) =>
        tester.getSize(_text('100 SVT Text')).height;
    // Where the text itself ends: the box it sits in is as wide as the column.
    double captionWidth(WidgetTester tester) {
      final RenderParagraph p = tester.renderObject<RenderParagraph>(
        _text('100 SVT Text'),
      );
      final String text = p.text.toPlainText();
      return p
          .getBoxesForSelection(
            TextSelection(baseOffset: 0, extentOffset: text.length),
          )
          .map((TextBox b) => b.right)
          .reduce((double a, double b) => a > b ? a : b);
    }

    testWidgets('line spacing changes the height of a line', (
      WidgetTester tester,
    ) async {
      await _open(tester);
      final double normal = captionHeight(tester);
      await _openOptions(tester);

      await _drag(tester, textTvReaderLineKey, toEnd: true);
      expect(captionHeight(tester), greaterThan(normal));

      await _drag(tester, textTvReaderLineKey, toEnd: false);
      expect(captionHeight(tester), lessThan(normal));
    });

    testWidgets('letter spacing widens the text', (WidgetTester tester) async {
      await _open(tester);
      final double normal = captionWidth(tester);
      await _openOptions(tester);

      await _drag(tester, textTvReaderLetterKey, toEnd: true);

      expect(captionWidth(tester), greaterThan(normal));
    });

    testWidgets('margins move the text in from the edge', (
      WidgetTester tester,
    ) async {
      await _open(tester);
      final double edge = _columnLeft;
      double inset() => tester.getTopLeft(_text('100 SVT Text')).dx - edge;
      expect(inset(), closeTo(readerMargins[readerDefaultMargin], 0.5));
      await _openOptions(tester);

      await _drag(tester, textTvReaderMarginKey, toEnd: true);
      expect(inset(), closeTo(readerMargins.last, 0.5));

      await _drag(tester, textTvReaderMarginKey, toEnd: false);
      expect(inset(), closeTo(readerMargins.first, 0.5));
    });

    testWidgets('bold thickens the text, and turns off again', (
      WidgetTester tester,
    ) async {
      await _open(tester);
      expect(_weight(tester, 'Incidenter'), isNull);
      await _openOptions(tester);

      await tester.tap(find.byKey(textTvReaderBoldKey));
      await tester.pumpAndSettle();
      expect(_weight(tester, 'Incidenter'), FontWeight.w700);

      await tester.tap(find.byKey(textTvReaderBoldKey));
      await tester.pumpAndSettle();
      expect(_weight(tester, 'Incidenter'), isNull);
    });

    testWidgets('the text stays left-aligned', (WidgetTester tester) async {
      await _open(
        tester,
        reader: const ReaderSettings(enabled: true, margin: 4, lineSpacing: 4),
      );

      final RenderParagraph p = tester.renderObject<RenderParagraph>(
        _text('Incidenter'),
      );
      expect(p.textAlign, anyOf(TextAlign.start, TextAlign.left));
    });
  });

  group('keeping them', () {
    testWidgets('every change is reported with the rest of the settings', (
      WidgetTester tester,
    ) async {
      final List<ReaderSettings> heard = <ReaderSettings>[];
      await _open(
        tester,
        reader: const ReaderSettings(enabled: true, theme: ReaderTheme.beige),
        onReaderChanged: heard.add,
      );
      await _openOptions(tester);

      await _drag(tester, textTvReaderMarginKey, toEnd: true);
      await tester.tap(find.byKey(textTvReaderBoldKey));
      await tester.pumpAndSettle();

      expect(heard.last.margin, readerMargins.length - 1);
      expect(heard.last.bold, isTrue);
      expect(heard.last.theme, ReaderTheme.beige);
      expect(heard.last.enabled, isTrue);
    });

    testWidgets('no slider can be pushed outside its table', (
      WidgetTester tester,
    ) async {
      final List<ReaderSettings> heard = <ReaderSettings>[];
      await _open(tester, onReaderChanged: heard.add);
      await _openOptions(tester);

      for (final Key key in <Key>[
        textTvReaderLineKey,
        textTvReaderLetterKey,
        textTvReaderMarginKey,
      ]) {
        await _drag(tester, key, toEnd: true);
        await _drag(tester, key, toEnd: false);
        await _drag(tester, key, toEnd: true);
      }

      for (final ReaderSettings s in heard) {
        expect(
          s.lineSpacing,
          inInclusiveRange(0, readerLineHeights.length - 1),
        );
        expect(
          s.letterSpacing,
          inInclusiveRange(0, readerLetterSpacings.length - 1),
        );
        expect(s.margin, inInclusiveRange(0, readerMargins.length - 1));
      }
      expect(heard.last.lineSpacing, readerLineHeights.length - 1);
    });

    testWidgets('RESET puts the layout back and keeps colours and size', (
      WidgetTester tester,
    ) async {
      final List<ReaderSettings> heard = <ReaderSettings>[];
      await _open(
        tester,
        reader: const ReaderSettings(
          enabled: true,
          theme: ReaderTheme.paper,
          size: 5,
          lineSpacing: 4,
          letterSpacing: 3,
          margin: 4,
          bold: true,
        ),
        onReaderChanged: heard.add,
      );
      await _openOptions(tester);

      await tester.tap(find.byKey(textTvReaderResetKey));
      await tester.pumpAndSettle();

      expect(
        heard.last,
        const ReaderSettings(enabled: true, theme: ReaderTheme.paper, size: 5),
      );
      expect(
        tester.widget<Switch>(find.byKey(textTvReaderBoldKey)).value,
        isFalse,
      );
    });

    testWidgets('opens with the saved layout', (WidgetTester tester) async {
      await _open(
        tester,
        reader: const ReaderSettings(enabled: true, margin: 4, bold: true),
      );
      final double edge = _columnLeft;

      expect(
        tester.getTopLeft(_text('100 SVT Text')).dx - edge,
        closeTo(readerMargins.last, 0.5),
      );
      expect(_weight(tester, 'Incidenter'), FontWeight.w700);
    });
  });
}
