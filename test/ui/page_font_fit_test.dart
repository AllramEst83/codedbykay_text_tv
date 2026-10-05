import 'dart:io';

import 'package:codedbykay_text_tv/model/page_font_settings.dart';
import 'package:codedbykay_text_tv/model/text_tv_page.dart';
import 'package:codedbykay_text_tv/ui/text_tv_page_area.dart';
import 'package:codedbykay_text_tv/ui/theme.dart';
import 'package:codedbykay_text_tv/ui/tv_row.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

// Unlike the other widget tests these load the real fonts, because the point
// is how wide a cell of each face is: a plain test draws every face with
// square boxes, which hides the difference. Glyph advances are the same on
// every operating system, so this is safe to run in CI (unlike the goldens).

Future<void> _load(String family, String file) async {
  final FontLoader loader = FontLoader(family)
    ..addFont(
      Future<ByteData>.value(
        ByteData.sublistView(File(file).readAsBytesSync()),
      ),
    );
  await loader.load();
}

const TextTvPage _page = TextTvPage(
  number: 100,
  parts: <List<String>>[
    <String>['100 SVT Text', 'En rad med text'],
  ],
);

Future<double> _rowWidth(
  WidgetTester tester,
  PageFont font,
  double screenWidth,
) async {
  tester.view
    ..physicalSize = Size(screenWidth, 800)
    ..devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      theme: textTvTheme(),
      home: Scaffold(
        body: TvPageArea(
          number: 100,
          part: 0,
          loading: false,
          result: const TextTvShown(_page),
          onLink: (String _) {},
          onRetry: () {},
          font: font,
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return tester.getSize(find.byType(TvRow).first).width;
}

void main() {
  setUpAll(() async {
    await _load(kPixelFontFamily, 'fonts/PressStart2P-Regular.ttf');
    await _load(kBedsteadFontFamily, 'fonts/Bedstead-Regular.otf');
  });

  group('the page fills the width of the screen', () {
    for (final PageFont font in PageFont.values) {
      for (final double width in <double>[360, 411, 450]) {
        testWidgets('in ${font.name} on a screen ${width.round()} wide', (
          WidgetTester tester,
        ) async {
          final double row = await _rowWidth(tester, font, width);

          expect(row, greaterThan(width * 0.97), reason: 'row $row of $width');
          expect(row, lessThanOrEqualTo(width));
        });
      }
    }

    testWidgets('and both faces end up the same width', (
      WidgetTester tester,
    ) async {
      final double pixel = await _rowWidth(tester, PageFont.pixel, 450);
      final double bedstead = await _rowWidth(tester, PageFont.bedstead, 450);

      expect((pixel - bedstead).abs(), lessThan(450 * 0.02));
    });
  });
}
