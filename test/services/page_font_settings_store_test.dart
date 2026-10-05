import 'package:codedbykay_text_tv/model/page_font_settings.dart';
import 'package:codedbykay_text_tv/services/page_font_settings_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues(<String, Object>{}));

  group('PrefsPageFontSettingsStore', () {
    test('a first run gets the pixel face', () async {
      expect(
        await PrefsPageFontSettingsStore().load(),
        PageFontSettings.defaults,
      );
    });

    test('gives back what was saved, to a new store too', () async {
      await PrefsPageFontSettingsStore().save(
        const PageFontSettings(font: PageFont.bedstead),
      );

      expect(
        await PrefsPageFontSettingsStore().load(),
        const PageFontSettings(font: PageFont.bedstead),
      );
    });

    test('a damaged saved value gives the pixel face', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{
        PrefsPageFontSettingsStore.key: 'garbage',
      });

      expect(
        await PrefsPageFontSettingsStore().load(),
        PageFontSettings.defaults,
      );
    });
  });
}
