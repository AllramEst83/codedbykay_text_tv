import 'package:codedbykay_text_tv/model/reader_settings.dart';
import 'package:codedbykay_text_tv/services/reader_settings_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues(<String, Object>{}));

  group('PrefsReaderSettingsStore', () {
    test('a first run gets the defaults', () async {
      expect(await PrefsReaderSettingsStore().load(), const ReaderSettings());
    });

    test('gives back what was saved, to a new store too', () async {
      const ReaderSettings settings = ReaderSettings(
        enabled: true,
        theme: ReaderTheme.beige,
        size: 4,
      );

      await PrefsReaderSettingsStore().save(settings);

      expect(await PrefsReaderSettingsStore().load(), settings);
    });

    test('a damaged saved value gives the defaults', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{
        PrefsReaderSettingsStore.key: 'garbage',
      });

      expect(await PrefsReaderSettingsStore().load(), const ReaderSettings());
    });
  });
}
