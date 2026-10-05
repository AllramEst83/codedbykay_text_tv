import 'package:codedbykay_text_tv/model/reader_settings.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ReaderSettings', () {
    test('the defaults: off, black, a middling size', () {
      const ReaderSettings s = ReaderSettings();

      expect(s.enabled, isFalse);
      expect(s.theme, ReaderTheme.black);
      expect(s.size, readerDefaultSize);
      expect(s.fontSize, readerTextSizes[readerDefaultSize]);
    });

    test('survives a round trip, every theme', () {
      for (final ReaderTheme theme in ReaderTheme.values) {
        final ReaderSettings s = ReaderSettings(
          enabled: true,
          theme: theme,
          size: 5,
        );

        expect(ReaderSettings.decode(s.encode()), s);
      }
    });

    test('copyWith changes only what it is told to', () {
      const ReaderSettings s = ReaderSettings(
        theme: ReaderTheme.beige,
        size: 3,
      );

      expect(
        s.copyWith(enabled: true),
        const ReaderSettings(enabled: true, theme: ReaderTheme.beige, size: 3),
      );
      expect(s.copyWith(size: 4).theme, ReaderTheme.beige);
    });

    test('nothing saved, or nonsense, gives the defaults', () {
      for (final String? bad in <String?>[null, '', 'x', '[]', '7', '{']) {
        expect(
          ReaderSettings.decode(bad),
          const ReaderSettings(),
          reason: '$bad',
        );
      }
    });

    test('a bad field is replaced and the good ones kept', () {
      expect(
        ReaderSettings.decode('{"enabled": true, "theme": "neon", "size": 99}'),
        const ReaderSettings(enabled: true),
      );
      expect(
        ReaderSettings.decode(
          '{"enabled": "yes", "theme": "paper", "size": -1}',
        ),
        const ReaderSettings(theme: ReaderTheme.paper),
      );
      expect(
        ReaderSettings.decode('{"theme": 4, "size": 1.5}'),
        const ReaderSettings(),
      );
    });

    test('sizes grow with the step', () {
      for (int i = 1; i < readerTextSizes.length; i++) {
        expect(readerTextSizes[i], greaterThan(readerTextSizes[i - 1]));
      }
    });
  });
}
