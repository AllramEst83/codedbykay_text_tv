import 'package:codedbykay_text_tv/model/crt_geometry.dart';
import 'package:codedbykay_text_tv/model/crt_settings.dart';
import 'package:codedbykay_text_tv/model/styled_text.dart';
import 'package:codedbykay_text_tv/model/text_tv_page.dart';
import 'package:codedbykay_text_tv/ui/crt_hit_map.dart';
import 'package:codedbykay_text_tv/ui/theme.dart';
import 'package:codedbykay_text_tv/ui/tv_row.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const Size _area = Size(400, 600);

/// Puts [child] in an area of [_area], at the top left of the screen.
Future<void> _pump(WidgetTester tester, Widget child) async {
  tester.view
    ..physicalSize = _area
    ..devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      theme: textTvTheme(),
      home: Align(
        alignment: Alignment.topLeft,
        child: SizedBox.fromSize(size: _area, child: child),
      ),
    ),
  );
}

/// The screen point where the glass shows the page point [page]: the inverse
/// of [crtSourcePoint], found by closing in on it (the glass is gentle, so
/// this converges quickly).
Offset _whereShown(Offset page, double curve) {
  Offset screen = page;
  for (int i = 0; i < 50; i++) {
    final ({double x, double y}) s = crtSourcePoint(
      screen.dx,
      screen.dy,
      _area.width,
      _area.height,
      curve,
    )!;
    screen += page - Offset(s.x, s.y);
  }
  return screen;
}

void main() {
  group('CrtHitMap', () {
    testWidgets('a flat screen leaves taps where they land', (
      WidgetTester tester,
    ) async {
      final List<Offset> taps = <Offset>[];
      await _pump(
        tester,
        CrtHitMap(
          curve: 0,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapUp: (TapUpDetails d) => taps.add(d.localPosition),
          ),
        ),
      );

      await tester.tapAt(const Offset(37, 411));

      expect(taps.single.dx, closeTo(37, 0.01));
      expect(taps.single.dy, closeTo(411, 0.01));
    });

    testWidgets('a tap reaches the point of the page the glass shows there', (
      WidgetTester tester,
    ) async {
      final List<Offset> taps = <Offset>[];
      await _pump(
        tester,
        CrtHitMap(
          curve: crtCurveMax,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapUp: (TapUpDetails d) => taps.add(d.localPosition),
          ),
        ),
      );

      for (final Offset screen in const <Offset>[
        Offset(300, 100),
        Offset(60, 480),
        Offset(200, 150),
      ]) {
        taps.clear();
        await tester.tapAt(screen);
        final ({double x, double y}) expected = crtSourcePoint(
          screen.dx,
          screen.dy,
          _area.width,
          _area.height,
          crtCurveMax,
        )!;

        expect(taps.single.dx, closeTo(expected.x, 0.01), reason: '$screen');
        expect(taps.single.dy, closeTo(expected.y, 0.01), reason: '$screen');
        // And it is a real shift, not the same point.
        expect((taps.single - screen).distance, greaterThan(1));
      }
    });

    testWidgets('a tap in the dark corner of the glass reaches nothing', (
      WidgetTester tester,
    ) async {
      final List<Offset> taps = <Offset>[];
      await _pump(
        tester,
        CrtHitMap(
          curve: crtCurveMax,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapUp: (TapUpDetails d) => taps.add(d.localPosition),
          ),
        ),
      );

      await tester.tapAt(const Offset(1, 1));
      expect(taps, isEmpty);

      await tester.tapAt(const Offset(200, 300));
      expect(taps, hasLength(1));
    });

    testWidgets('a change of curve applies to the next tap', (
      WidgetTester tester,
    ) async {
      final List<Offset> taps = <Offset>[];
      Widget map(double curve) => CrtHitMap(
        curve: curve,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapUp: (TapUpDetails d) => taps.add(d.localPosition),
        ),
      );
      await _pump(tester, map(0));
      await tester.tapAt(const Offset(300, 100));
      expect(taps.last.dx, closeTo(300, 0.01));

      await _pump(tester, map(crtCurveMax));
      await tester.tapAt(const Offset(300, 100));
      expect((taps.last - const Offset(300, 100)).distance, greaterThan(1));
    });
  });

  group('a link on the glass', () {
    // A page of one linked word, drawn where it is laid out; the glass shows
    // it somewhere else, and a tap there must open it.
    Future<List<String>> pumpLink(WidgetTester tester, double curve) async {
      final List<String> opened = <String>[];
      final List<StyledRun> row = <StyledRun>[
        const StyledRun('  '),
        const StyledRun('377', underline: true, command: '377'),
        StyledRun(''.padRight(textTvColumns - 5)),
      ];
      await _pump(
        tester,
        CrtHitMap(
          curve: curve,
          child: Align(
            // Well in from the edge and below the middle: where the glass moves
            // things the most.
            alignment: const Alignment(0.5, 0.4),
            child: SizedBox(
              width: 240,
              child: TvRow(
                runs: row,
                columns: textTvColumns,
                style: const TextStyle(
                  fontFamily: kPixelFontFamily,
                  fontSize: 8,
                  height: 1.6,
                ),
                onRun: opened.add,
              ),
            ),
          ),
        ),
      );
      return opened;
    }

    for (final double curve in <double>[0, 0.03, crtCurveMax]) {
      testWidgets(
        'is opened by a tap where the glass shows it (curve $curve)',
        (WidgetTester tester) async {
          final List<String> opened = await pumpLink(tester, curve);
          // The link's middle as laid out, then where the glass puts it.
          final Rect row = tester.getRect(find.byType(TvRow));
          final double cell = row.width / (textTvColumns + tvGutterCells);
          final Offset laidOut = Offset(
            row.left + cell * (1 + 2 + 1.5),
            row.center.dy,
          );

          await tester.tapAt(_whereShown(laidOut, curve));

          expect(opened, <String>['377']);
        },
      );
    }

    testWidgets(
      'at the strongest bulge the flat position misses, the shown one hits',
      (WidgetTester tester) async {
        // Where the word is laid out, and where the glass shows it.
        await pumpLink(tester, 0);
        final Rect row = tester.getRect(find.byType(TvRow));
        final double cell = row.width / (textTvColumns + tvGutterCells);
        final Offset laidOut = Offset(
          row.left + cell * (1 + 2 + 1.5),
          row.center.dy,
        );
        final Offset shown = _whereShown(laidOut, crtCurveMax);

        // The glass shows the word further from where it is laid out than a row
        // is tall...
        expect((shown - laidOut).distance, greaterThan(4));

        // ...so on a screen with no mapping (what every tap did before), a tap
        // on the word as the glass shows it lands beside it.
        final List<String> unmapped = await pumpLink(tester, 0);
        await tester.tapAt(shown);
        expect(unmapped, isEmpty);

        // With the mapping the same tap opens it.
        final List<String> mapped = await pumpLink(tester, crtCurveMax);
        await tester.tapAt(shown);
        expect(mapped, <String>['377']);
      },
    );
  });
}
