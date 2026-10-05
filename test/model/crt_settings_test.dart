import 'package:codedbykay_text_tv/model/crt_settings.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CrtSettings', () {
    test('starts switched off with a mild look', () {
      final CrtSettings s = CrtSettings.defaults;

      expect(s.enabled, isFalse);
      expect(s.curve, 0.03);
      expect(s.scanDepth, 0.18);
      expect(s.scanPeriod, 3);
      expect(CrtSettings(), s);
    });

    test('every value is held inside its range, whoever sets it', () {
      final CrtSettings high = CrtSettings(
        curve: 5,
        scanDepth: 5,
        scanPeriod: 500,
      );
      expect(high.curve, crtCurveMax);
      expect(high.scanDepth, crtScanDepthMax);
      expect(high.scanPeriod, crtScanPeriodMax);

      final CrtSettings low = CrtSettings(
        curve: -1,
        scanDepth: -1,
        scanPeriod: 0,
      );
      expect(low.curve, 0);
      expect(low.scanDepth, 0);
      expect(low.scanPeriod, crtScanPeriodMin);
    });

    test('a value that is not a number falls back to the default', () {
      final CrtSettings s = CrtSettings(
        curve: double.nan,
        scanDepth: double.infinity,
        scanPeriod: double.negativeInfinity,
      );

      expect(s.curve, CrtSettings.defaults.curve);
      expect(s.scanDepth, CrtSettings.defaults.scanDepth);
      expect(s.scanPeriod, CrtSettings.defaults.scanPeriod);
    });

    test('the caps are modest: a page stays readable at the largest', () {
      expect(crtCurveMax, lessThanOrEqualTo(0.06));
      expect(crtScanDepthMax, lessThanOrEqualTo(0.35));
      expect(crtScanPeriodMin, greaterThanOrEqualTo(2));
    });

    test('copyWith changes only what it is told to, and keeps the caps', () {
      final CrtSettings s = CrtSettings(curve: 0.02, scanPeriod: 4);

      expect(s.copyWith(enabled: true).curve, 0.02);
      expect(s.copyWith(scanDepth: 0.3).scanPeriod, 4);
      expect(s.copyWith(curve: 9).curve, crtCurveMax);
    });

    test('reset puts the looks back and leaves the switch alone', () {
      final CrtSettings s = CrtSettings(
        enabled: true,
        curve: 0.05,
        scanDepth: 0.3,
        scanPeriod: 5,
      );

      expect(s.reset(), CrtSettings.defaults.copyWith(enabled: true));
    });

    test('survives a round trip', () {
      final CrtSettings s = CrtSettings(
        enabled: true,
        curve: 0.045,
        scanDepth: 0.25,
        scanPeriod: 4.5,
      );

      expect(CrtSettings.decode(s.encode()), s);
    });

    test('nothing saved, or nonsense, gives the defaults', () {
      for (final String? bad in <String?>[null, '', 'x', '[]', '7', '{']) {
        expect(CrtSettings.decode(bad), CrtSettings.defaults, reason: '$bad');
      }
    });

    test('a saved value out of range is brought into range', () {
      final CrtSettings s = CrtSettings.decode(
        '{"enabled": true, "curve": 3, "scanDepth": -2, "scanPeriod": 99}',
      );

      expect(s.enabled, isTrue);
      expect(s.curve, crtCurveMax);
      expect(s.scanDepth, 0);
      expect(s.scanPeriod, crtScanPeriodMax);
    });

    test('a bad field is replaced and the good ones kept', () {
      final CrtSettings s = CrtSettings.decode(
        '{"enabled": "yes", "curve": "wide", "scanDepth": 0.2, "scanPeriod": null}',
      );

      expect(s.enabled, isFalse);
      expect(s.curve, CrtSettings.defaults.curve);
      expect(s.scanDepth, 0.2);
      expect(s.scanPeriod, CrtSettings.defaults.scanPeriod);
    });

    test('whole numbers saved by hand are accepted', () {
      expect(CrtSettings.decode('{"scanPeriod": 4}').scanPeriod, 4);
    });
  });
}
