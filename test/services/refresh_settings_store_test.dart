import 'package:codedbykay_text_tv/model/refresh_settings.dart';
import 'package:codedbykay_text_tv/services/refresh_settings_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues(<String, Object>{}));

  group('PrefsRefreshSettingsStore', () {
    test('a first run gets the default', () async {
      expect(await PrefsRefreshSettingsStore().load(), const RefreshSettings());
    });

    test('gives back what was saved, to a new store too', () async {
      await PrefsRefreshSettingsStore().save(const RefreshSettings(auto: 2));

      expect(
        await PrefsRefreshSettingsStore().load(),
        const RefreshSettings(auto: 2),
      );
    });

    test('a damaged saved value gives the default', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{
        PrefsRefreshSettingsStore.key: 'garbage',
      });

      expect(await PrefsRefreshSettingsStore().load(), const RefreshSettings());
    });
  });
}
