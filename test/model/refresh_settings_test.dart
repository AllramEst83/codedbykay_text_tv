import 'package:codedbykay_text_tv/model/refresh_settings.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('RefreshSettings', () {
    test('never refreshes by default', () {
      const RefreshSettings s = RefreshSettings();

      expect(s.auto, 0);
      expect(s.interval, isNull);
    });

    test('the steps are never, then 30 s, 60 s and 2 min', () {
      expect(autoRefreshIntervals, <Duration?>[
        null,
        const Duration(seconds: 30),
        const Duration(seconds: 60),
        const Duration(minutes: 2),
      ]);
      expect(
        const RefreshSettings(auto: 2).interval,
        const Duration(seconds: 60),
      );
    });

    test('no step asks the site more often than every 30 seconds', () {
      for (final Duration? every in autoRefreshIntervals) {
        if (every != null) {
          expect(every, greaterThanOrEqualTo(const Duration(seconds: 30)));
        }
      }
    });

    test('a page left for a couple of minutes is stale on return', () {
      expect(refreshAfterResume, const Duration(minutes: 2));
    });

    test('survives a round trip', () {
      for (int auto = 0; auto < autoRefreshIntervals.length; auto++) {
        final RefreshSettings s = RefreshSettings(auto: auto);

        expect(RefreshSettings.decode(s.encode()), s);
      }
    });

    test('nothing saved, or nonsense, means never', () {
      for (final String? bad in <String?>[null, '', 'x', '[]', '7', '{']) {
        expect(
          RefreshSettings.decode(bad),
          const RefreshSettings(),
          reason: '$bad',
        );
      }
    });

    test('a step that is not in the table means never', () {
      for (final String bad in <String>[
        '-1',
        '4',
        '99',
        '"x"',
        '1.5',
        'null',
      ]) {
        expect(
          RefreshSettings.decode('{"auto": $bad}'),
          const RefreshSettings(),
          reason: bad,
        );
      }
    });

    test('copyWith changes the step', () {
      expect(const RefreshSettings().copyWith(auto: 3).auto, 3);
    });
  });
}
