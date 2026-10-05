import 'package:codedbykay_text_tv/model/text_tv_page.dart';
import 'package:codedbykay_text_tv/model/text_tv_session.dart';
import 'package:codedbykay_text_tv/ui/page_turn.dart';
import 'package:codedbykay_text_tv/ui/text_tv_keys.dart';
import 'package:codedbykay_text_tv/ui/text_tv_screen.dart';
import 'package:codedbykay_text_tv/ui/theme.dart';
import 'package:codedbykay_text_tv/ui/tv_row.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fakes/fake_text_tv_repository.dart';

const Key _box = ValueKey<String>('box');

Widget _turn(int direction, {Key? key, bool disableAnimations = false}) =>
    MediaQuery(
      data: MediaQueryData(disableAnimations: disableAnimations),
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: Align(
          alignment: Alignment.topLeft,
          child: PageTurn(
            key: key,
            direction: direction,
            child: const SizedBox(key: _box, width: 200, height: 100),
          ),
        ),
      ),
    );

double _opacity(WidgetTester tester) =>
    tester.widget<Opacity>(find.byType(Opacity)).opacity;

void main() {
  group('PageTurn', () {
    testWidgets('a later page starts to the right, faded, and settles', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(_turn(1));

      expect(tester.getTopLeft(find.byKey(_box)).dx, closeTo(20, 0.01));
      expect(_opacity(tester), 0);

      await tester.pump(PageTurn.duration);

      expect(tester.getTopLeft(find.byKey(_box)).dx, closeTo(0, 0.01));
      expect(_opacity(tester), 1);
    });

    testWidgets('an earlier page starts to the left', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(_turn(-1));

      expect(tester.getTopLeft(find.byKey(_box)).dx, closeTo(-20, 0.01));

      await tester.pump(PageTurn.duration);
      expect(tester.getTopLeft(find.byKey(_box)).dx, closeTo(0, 0.01));
    });

    testWidgets('moves in between, getting nearer and clearer', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(_turn(1));
      await tester.pump(PageTurn.duration ~/ 3);
      final double earlyX = tester.getTopLeft(find.byKey(_box)).dx;
      final double earlyOpacity = _opacity(tester);

      await tester.pump(PageTurn.duration ~/ 3);

      expect(tester.getTopLeft(find.byKey(_box)).dx, lessThan(earlyX));
      expect(_opacity(tester), greaterThan(earlyOpacity));
      expect(earlyX, inExclusiveRange(0, 20));
    });

    testWidgets('no direction means no animation: it is simply there', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(_turn(0));

      expect(tester.getTopLeft(find.byKey(_box)).dx, 0);
      expect(_opacity(tester), 1);
    });

    testWidgets('the phone asking for no animations gets none', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(_turn(1, disableAnimations: true));

      expect(tester.getTopLeft(find.byKey(_box)).dx, 0);
      expect(_opacity(tester), 1);
    });

    testWidgets('a short turn: a fifth of a second at most', (
      WidgetTester tester,
    ) async {
      expect(
        PageTurn.duration,
        lessThanOrEqualTo(const Duration(milliseconds: 200)),
      );
    });

    testWidgets('a new key is a new turn, and the old page is gone at once', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(_turn(1, key: const ValueKey<int>(1)));
      await tester.pump(PageTurn.duration);

      await tester.pumpWidget(_turn(1, key: const ValueKey<int>(2)));

      expect(find.byKey(_box), findsOneWidget, reason: 'never two pages');
      expect(tester.getTopLeft(find.byKey(_box)).dx, closeTo(20, 0.01));
    });
  });

  group('in the viewer', () {
    TextTvPage page(int n) => TextTvPage(
      number: n,
      parts: <List<String>>[
        <String>['$n SVT Text', '', 'Sida $n'],
      ],
      previous: n - 1,
      next: n + 1,
    );

    Future<void> open(WidgetTester tester) async {
      tester.view
        ..physicalSize = const Size(800, 2400)
        ..devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp(
          theme: textTvTheme(),
          home: TextTvScreen(
            repository: FakeTextTvRepository(<int, TextTvPage>{
              for (int n = 100; n <= 399; n++) n: page(n),
            }),
            initial: const TextTvSession(page: 300),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    double rowX(WidgetTester tester) =>
        tester.getTopLeft(find.byType(TvRow).first).dx;

    testWidgets('the first page is simply there', (WidgetTester tester) async {
      await tester.pumpWidget(const SizedBox());
      await open(tester);

      expect(find.byType(PageTurn), findsOneWidget);
      expect(tester.widget<PageTurn>(find.byType(PageTurn)).direction, 0);
    });

    testWidgets('the next page slides in from the right', (
      WidgetTester tester,
    ) async {
      await open(tester);
      final double rest = rowX(tester);

      await tester.tap(find.byKey(textTvNextKey));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 20));

      expect(rowX(tester), greaterThan(rest));
      await tester.pumpAndSettle();
      expect(rowX(tester), closeTo(rest, 0.5));
    });

    testWidgets('the previous page slides in from the left', (
      WidgetTester tester,
    ) async {
      await open(tester);
      final double rest = rowX(tester);

      await tester.tap(find.byKey(textTvPrevKey));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 20));

      expect(rowX(tester), lessThan(rest));
      await tester.pumpAndSettle();
      expect(rowX(tester), closeTo(rest, 0.5));
    });

    testWidgets('there is only ever one page in the tree while it turns', (
      WidgetTester tester,
    ) async {
      await open(tester);
      final int rows = tester.widgetList(find.byType(TvRow)).length;

      await tester.tap(find.byKey(textTvNextKey));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 20));

      expect(tester.widgetList(find.byType(TvRow)), hasLength(rows));
      expect(find.byType(PageTurn), findsOneWidget);
    });

    testWidgets('reading the same page again does not turn it', (
      WidgetTester tester,
    ) async {
      await open(tester);
      final double rest = rowX(tester);

      await tester.tap(find.byKey(textTvRefreshKey));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 20));

      expect(rowX(tester), closeTo(rest, 0.5));
    });

    testWidgets('a page chosen from the chips turns by which way it goes', (
      WidgetTester tester,
    ) async {
      await open(tester);

      await tester.tap(find.byKey(textTvChipKey(100)));
      await tester.pump();

      expect(tester.widget<PageTurn>(find.byType(PageTurn)).direction, -1);
    });
  });
}
