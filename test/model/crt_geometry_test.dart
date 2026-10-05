import 'dart:math' as math;

import 'package:codedbykay_text_tv/model/crt_geometry.dart';
import 'package:codedbykay_text_tv/model/crt_settings.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const double w = 400;
  const double h = 600;

  ({double x, double y}) at(double x, double y, double curve) =>
      crtSourcePoint(x, y, w, h, curve)!;

  group('crtSourcePoint', () {
    test('a flat screen maps every point to itself', () {
      for (final (double, double) p in <(double, double)>[
        (0, 0),
        (w, h),
        (13, 421),
        (200, 300),
      ]) {
        final ({double x, double y}) s = at(p.$1, p.$2, 0);
        expect(s.x, closeTo(p.$1, 1e-9));
        expect(s.y, closeTo(p.$2, 1e-9));
      }
    });

    test('the middle, and the middle of each edge, stay where they are', () {
      for (final double curve in <double>[0.01, 0.03, crtCurveMax]) {
        for (final (double, double) p in <(double, double)>[
          (w / 2, h / 2),
          (0, h / 2),
          (w, h / 2),
          (w / 2, 0),
          (w / 2, h),
        ]) {
          final ({double x, double y}) s = at(p.$1, p.$2, curve);
          expect(s.x, closeTo(p.$1, 1e-9), reason: '$p at $curve');
          expect(s.y, closeTo(p.$2, 1e-9), reason: '$p at $curve');
        }
      }
    });

    test('the glass shows points further out than the screen point is', () {
      // Left of the middle, nearer to the middle than the edge: the picture
      // there comes from further in (the middle is magnified).
      final ({double x, double y}) s = at(w * 0.8, h / 2, 0.06);

      expect(s.x, lessThan(w * 0.8));
      expect(s.x, greaterThan(w / 2));
      expect(s.y, closeTo(h / 2, 1e-9));
    });

    test(
      'the miss is largest 58% of the way out, and grows with the curve',
      () {
        double worst(double curve) {
          double most = 0;
          for (double x = w / 2; x <= w; x += 1) {
            most = math.max(most, (at(x, h / 2, curve).x - x).abs());
          }
          return most;
        }

        // k * 0.385 / (1 + k) of half the width.
        for (final double curve in <double>[0.03, 0.06]) {
          expect(
            worst(curve),
            closeTo(curve * 0.3849 / (1 + curve) * (w / 2), 0.2),
          );
        }
        expect(worst(0.06), greaterThan(worst(0.03) * 1.8));
      },
    );

    test('the dark corners of the glass are not on the page at all', () {
      expect(crtSourcePoint(0, 0, w, h, 0.03), isNull);
      expect(crtSourcePoint(w, h, w, h, 0.03), isNull);
      expect(crtSourcePoint(w / 2, h / 2, w, h, 0.03), isNotNull);
    });

    test('a flat screen has no dark corners', () {
      expect(crtSourcePoint(0, 0, w, h, 0), isNotNull);
      expect(crtSourcePoint(w, h, w, h, 0), isNotNull);
    });

    test('an empty area maps nothing', () {
      expect(crtSourcePoint(1, 1, 0, h, 0.03), isNull);
      expect(crtSourcePoint(1, 1, w, 0, 0.03), isNull);
    });
  });
}
