import 'dart:io';

import 'package:codedbykay_text_tv/model/text_tv_page.dart';
import 'package:codedbykay_text_tv/services/text_tv.dart';
import 'package:codedbykay_text_tv/ui/text_tv_page_area.dart';
import 'package:codedbykay_text_tv/ui/theme.dart';
import 'package:codedbykay_text_tv/ui/tv_row.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fakes/fake_http_fetcher.dart';

TextTvPage _fixture(int n) =>
    TextTv(fetcher: FakeHttpFetcher())
        .parse(n, File('test/fixtures/texttv_$n.json').readAsStringSync())!;

Future<List<TvRow>> _rows(WidgetTester tester, int page) async {
  tester.view
    ..physicalSize = const Size(400, 800)
    ..devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      theme: textTvTheme(),
      home: Scaffold(
        body: TvPageArea(
          number: page,
          part: 0,
          loading: false,
          result: TextTvShown(_fixture(page)),
          onLink: (String _) {},
          onRetry: () {},
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return tester.widgetList<TvRow>(find.byType(TvRow)).toList();
}

void main() {
  for (final int page in <int>[101, 400]) {
    testWidgets(
      'the rows of the big lettering on page $page share one margin',
      (WidgetTester tester) async {
        final List<TvRow> rows = await _rows(tester, page);

        // Rows 1 to 4: the lettering, the last row of it on black.
        final Set<int> margins = <int>{
          for (int i = 1; i <= 4; i++) rows[i].gutterLeft,
        };
        expect(margins, hasLength(1), reason: 'was $margins');
      },
    );
  }
}
