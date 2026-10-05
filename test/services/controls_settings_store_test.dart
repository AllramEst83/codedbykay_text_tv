import 'package:codedbykay_text_tv/model/controls_settings.dart';
import 'package:codedbykay_text_tv/services/controls_settings_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues(<String, Object>{}));

  group('PrefsControlsSettingsStore', () {
    test('a first run gets the classic controls', () async {
      expect(
        await PrefsControlsSettingsStore().load(),
        ControlsSettings.defaults,
      );
    });

    test('gives back what was saved, to a new store too', () async {
      await PrefsControlsSettingsStore().save(
        const ControlsSettings(quickEntry: true),
      );

      expect(
        await PrefsControlsSettingsStore().load(),
        const ControlsSettings(quickEntry: true),
      );
    });

    test('a damaged saved value gives the classic controls', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{
        PrefsControlsSettingsStore.key: 'garbage',
      });

      expect(
        await PrefsControlsSettingsStore().load(),
        ControlsSettings.defaults,
      );
    });
  });
}
