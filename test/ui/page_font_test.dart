import 'package:codedbykay_text_tv/model/page_font_settings.dart';
import 'package:codedbykay_text_tv/model/text_tv_page.dart';
import 'package:codedbykay_text_tv/ui/text_tv_keys.dart';
import 'package:codedbykay_text_tv/ui/text_tv_screen.dart';
import 'package:codedbykay_text_tv/ui/theme.dart';
import 'package:codedbykay_text_tv/ui/tv_row.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fakes/english.dart';
import '../fakes/fake_text_tv_repository.dart';

FakeTextTvRepository _repository() => FakeTextTvRepository(<int, TextTvPage>{
  100: const TextTvPage(
    number: 100,
    parts: <List<String>>[
      <String>['100 SVT Text', 'Hej'],
    ],
  ),
});

Future<List<PageFontSettings>> _open(
  WidgetTester tester, {
  PageFontSettings pageFont = PageFontSettings.defaults,
}) async {
  tester.view
    ..physicalSize = const Size(800, 3000)
    ..devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final List<PageFontSettings> heard = <PageFontSettings>[];
  await tester.pumpWidget(
    MaterialApp(
      theme: textTvTheme(),
      home: TextTvScreen(
        repository: _repository(),
        pageFont: pageFont,
        onPageFontChanged: heard.add,
      ),
    ),
  );
  await tester.pumpAndSettle();
  return heard;
}

TvRow _firstRow(WidgetTester tester) =>
    tester.widget<TvRow>(find.byType(TvRow).first);

Future<void> _openSettings(WidgetTester tester) async {
  await tester.tap(find.byKey(textTvSettingsKey));
  await tester.pumpAndSettle();
}

void main() {
  group('the teletext font', () {
    testWidgets('the page starts in the pixel face', (
      WidgetTester tester,
    ) async {
      await _open(tester);

      expect(_firstRow(tester).style?.fontFamily, kPixelFontFamily);
      expect(_firstRow(tester).stretchGlyphs, isTrue);
    });

    testWidgets('a saved choice of Bedstead is used, and not stretched', (
      WidgetTester tester,
    ) async {
      await _open(
        tester,
        pageFont: const PageFontSettings(font: PageFont.bedstead),
      );

      expect(_firstRow(tester).style?.fontFamily, kBedsteadFontFamily);
      expect(_firstRow(tester).stretchGlyphs, isFalse);
    });

    test('a Bedstead row is two cells tall, a pixel row 1.6', () {
      expect(pageRowCells(PageFont.bedstead), 2.0);
      expect(pageRowCells(PageFont.pixel), 1.6);
    });
  });

  group('in settings', () {
    testWidgets('a group with both fonts, a preview and a note', (
      WidgetTester tester,
    ) async {
      await _open(tester);
      await _openSettings(tester);
      await tester.scrollUntilVisible(find.byKey(textTvPageFontNoteKey), 200);

      expect(find.byKey(textTvSettingsGroupKey('pagefont')), findsOneWidget);
      expect(find.text(en.sectionPageFont), findsOneWidget);
      for (final PageFont f in PageFont.values) {
        expect(find.byKey(textTvPageFontKey(f)), findsOneWidget);
      }
      expect(find.byKey(textTvPageFontPreviewKey), findsOneWidget);
      expect(find.text(en.pageFontNote), findsOneWidget);
    });

    testWidgets('choosing Bedstead changes the page and says so', (
      WidgetTester tester,
    ) async {
      final List<PageFontSettings> heard = await _open(tester);
      await _openSettings(tester);
      await tester.scrollUntilVisible(
        find.byKey(textTvPageFontKey(PageFont.bedstead)),
        200,
      );

      await tester.tap(find.byKey(textTvPageFontKey(PageFont.bedstead)));
      await tester.pumpAndSettle();
      expect(heard.last.font, PageFont.bedstead);

      await tester.tap(find.byKey(textTvSettingsBackKey));
      await tester.pumpAndSettle();
      expect(_firstRow(tester).style?.fontFamily, kBedsteadFontFamily);
    });

    testWidgets('the preview shows the font chosen', (
      WidgetTester tester,
    ) async {
      await _open(
        tester,
        pageFont: const PageFontSettings(font: PageFont.bedstead),
      );
      await _openSettings(tester);
      await tester.scrollUntilVisible(
        find.byKey(textTvPageFontPreviewKey),
        200,
      );

      final Finder rows = find.descendant(
        of: find.byKey(textTvPageFontPreviewKey),
        matching: find.byType(TvRow),
      );
      expect(rows, findsWidgets);
      expect(
        tester.widget<TvRow>(rows.first).style?.fontFamily,
        kBedsteadFontFamily,
      );
    });

    testWidgets('choosing what is already chosen reports nothing', (
      WidgetTester tester,
    ) async {
      final List<PageFontSettings> heard = await _open(tester);
      await _openSettings(tester);
      await tester.scrollUntilVisible(
        find.byKey(textTvPageFontKey(PageFont.pixel)),
        200,
      );

      await tester.tap(find.byKey(textTvPageFontKey(PageFont.pixel)));
      await tester.pumpAndSettle();

      expect(heard, isEmpty);
    });
  });
}
