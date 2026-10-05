import 'package:codedbykay_text_tv/model/controls_settings.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ControlsSettings', () {
    test(
      'starts with the classic controls, which leave the page most room',
      () {
        expect(const ControlsSettings().quickEntry, isFalse);
        expect(ControlsSettings.defaults, const ControlsSettings());
      },
    );

    test('copyWith turns the quick pad on and off', () {
      const ControlsSettings off = ControlsSettings();

      expect(off.copyWith(quickEntry: true).quickEntry, isTrue);
      expect(off.copyWith(quickEntry: true).copyWith(quickEntry: false), off);
      expect(off.copyWith(), off);
    });

    test('survives a round trip, both ways', () {
      for (final bool on in <bool>[true, false]) {
        final ControlsSettings s = ControlsSettings(quickEntry: on);

        expect(ControlsSettings.decode(s.encode()), s);
      }
    });

    test('nothing saved, or nonsense, gives the classic controls', () {
      for (final String? bad in <String?>[null, '', 'x', '[]', '7', '{']) {
        expect(
          ControlsSettings.decode(bad),
          ControlsSettings.defaults,
          reason: '$bad',
        );
      }
    });

    test('a value that is not a yes or no gives the classic controls', () {
      for (final String bad in <String>['1', '"yes"', 'null', '[]', '{}']) {
        expect(
          ControlsSettings.decode('{"quickEntry": $bad}'),
          ControlsSettings.defaults,
          reason: bad,
        );
      }
    });
  });
}
