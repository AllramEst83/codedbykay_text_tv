import 'package:codedbykay_text_tv/model/language_settings.dart';
import 'package:codedbykay_text_tv/services/language_settings_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues(<String, Object>{}));

  group('PrefsLanguageSettingsStore', () {
    test('a first run follows the phone', () async {
      expect(
        await PrefsLanguageSettingsStore().load(),
        LanguageSettings.defaults,
      );
    });

    test('gives back what was saved, to a new store too', () async {
      await PrefsLanguageSettingsStore().save(
        const LanguageSettings(language: AppLanguage.swedish),
      );

      expect(
        await PrefsLanguageSettingsStore().load(),
        const LanguageSettings(language: AppLanguage.swedish),
      );
    });

    test('a damaged saved value follows the phone', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{
        PrefsLanguageSettingsStore.key: 'garbage',
      });

      expect(
        await PrefsLanguageSettingsStore().load(),
        LanguageSettings.defaults,
      );
    });
  });
}
