@Tags(<String>['golden'])
library;

import 'dart:io';

import 'package:codedbykay_text_tv/model/page_font_settings.dart';
import 'package:codedbykay_text_tv/model/text_tv_page.dart';
import 'package:codedbykay_text_tv/services/text_tv.dart';
import 'package:codedbykay_text_tv/ui/text_tv_page_area.dart';
import 'package:codedbykay_text_tv/ui/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fakes/fake_http_fetcher.dart';

// Pictures of real pages drawn with the real pixel font, which a plain
// `flutter test` does not have (it draws boxes), so a regression in the layout
// or the colours shows as a changed picture.
//
// Fonts are drawn a little differently on each operating system, so these
// are made and checked on the same machine: they are left out of CI and run
// by hand.
//
//   flutter test --tags golden                    # check
//   flutter test --tags golden --update-goldens   # after a change you meant

Future<void> _loadFont(String family, String file) async {
  final FontLoader loader = FontLoader(family)
    ..addFont(
      Future<ByteData>.value(
        ByteData.sublistView(File(file).readAsBytesSync()),
      ),
    );
  await loader.load();
}

Future<void> _loadFonts() async {
  await _loadFont(kPixelFontFamily, 'fonts/PressStart2P-Regular.ttf');
  await _loadFont(kBedsteadFontFamily, 'fonts/Bedstead-Regular.otf');
}

TextTvPage _page(int n) =>
    TextTv(fetcher: FakeHttpFetcher())
        .parse(n, File('test/fixtures/texttv_$n.json').readAsStringSync())!;

Future<void> _draw(
  WidgetTester tester,
  TextTvPage page, {
  PageFont font = PageFont.pixel,
}) async {
  tester.view
    ..physicalSize = const Size(400, 640)
    ..devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: textTvTheme(),
      home: Scaffold(
        backgroundColor: TvColors.black,
        body: TvPageArea(
          number: page.number,
          part: 0,
          loading: false,
          result: TextTvShown(page),
          onLink: (String _) {},
          onRetry: () {},
          font: font,
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(_loadFonts);

  testWidgets('page 100, with the block-graphics header', (
    WidgetTester tester,
  ) async {
    await _draw(tester, _page(100));

    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/page_100.png'),
    );
  });

  testWidgets('page 377, a sports page in colour', (WidgetTester tester) async {
    await _draw(tester, _page(377));

    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/page_377.png'),
    );
  });

  testWidgets('page 100 in Bedstead', (WidgetTester tester) async {
    await _draw(tester, _page(100), font: PageFont.bedstead);

    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/page_100_bedstead.png'),
    );
  });

  testWidgets('page 377 in Bedstead', (WidgetTester tester) async {
    await _draw(tester, _page(377), font: PageFont.bedstead);

    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/page_377_bedstead.png'),
    );
  });

  testWidgets('page 101, a logo made of block graphics', (
    WidgetTester tester,
  ) async {
    await _draw(tester, _page(101));

    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/page_101.png'),
    );
  });

  testWidgets('page 400, weather', (WidgetTester tester) async {
    await _draw(tester, _page(400));

    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/page_400.png'),
    );
  });
}
