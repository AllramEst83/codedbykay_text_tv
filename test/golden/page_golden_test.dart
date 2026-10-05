@Tags(<String>['golden'])
library;

import 'dart:io';

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

Future<void> _loadPixelFont() async {
  final FontLoader loader = FontLoader(kPixelFontFamily)
    ..addFont(
      Future<ByteData>.value(
        ByteData.sublistView(
          File('fonts/PressStart2P-Regular.ttf').readAsBytesSync(),
        ),
      ),
    );
  await loader.load();
}

TextTvPage _page(int n) =>
    TextTv(fetcher: FakeHttpFetcher())
        .parse(n, File('test/fixtures/texttv_$n.json').readAsStringSync())!;

Future<void> _draw(WidgetTester tester, TextTvPage page) async {
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
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(_loadPixelFont);

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
}
