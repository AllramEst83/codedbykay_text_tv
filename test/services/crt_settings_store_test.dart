import 'package:codedbykay_text_tv/model/crt_settings.dart';
import 'package:codedbykay_text_tv/services/crt_settings_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues(<String, Object>{}));

  group('PrefsCrtSettingsStore', () {
    test('a first run gets the defaults', () async {
      expect(await PrefsCrtSettingsStore().load(), CrtSettings.defaults);
    });

    test('gives back what was saved, to a new store too', () async {
      final CrtSettings settings = CrtSettings(
        enabled: true,
        curve: 0.04,
        scanDepth: 0.22,
        scanPeriod: 3.5,
      );

      await PrefsCrtSettingsStore().save(settings);

      expect(await PrefsCrtSettingsStore().load(), settings);
    });

    test('a damaged saved value gives the defaults', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{
        PrefsCrtSettingsStore.key: 'garbage',
      });

      expect(await PrefsCrtSettingsStore().load(), CrtSettings.defaults);
    });
  });
}
