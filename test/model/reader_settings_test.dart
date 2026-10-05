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

    test('the layout defaults are the middle of each table', () {
      const ReaderSettings s = ReaderSettings();

      expect(s.lineHeight, 1.5);
      expect(s.letterSpacingEm, 0);
      expect(s.marginWidth, 20);
      expect(s.bold, isFalse);
    });

    test('the layout survives a round trip', () {
      const ReaderSettings s = ReaderSettings(
        enabled: true,
        theme: ReaderTheme.grey,
        size: 6,
        lineSpacing: 4,
        letterSpacing: 3,
        margin: 0,
        bold: true,
      );

      expect(ReaderSettings.decode(s.encode()), s);
    });

    test('a saved layout from before these existed gets the defaults', () {
      expect(
        ReaderSettings.decode('{"enabled": true, "theme": "paper", "size": 4}'),
        const ReaderSettings(enabled: true, theme: ReaderTheme.paper, size: 4),
      );
    });

    test('a layout step outside its table is replaced, the rest kept', () {
      final ReaderSettings s = ReaderSettings.decode(
        '{"lineSpacing": 99, "letterSpacing": -1, "margin": "wide", "bold": 1, "size": 3}',
      );

      expect(s.lineSpacing, readerDefaultLineSpacing);
      expect(s.letterSpacing, readerDefaultLetterSpacing);
      expect(s.margin, readerDefaultMargin);
      expect(s.bold, isFalse);
      expect(s.size, 3);
    });

    test('resetLayout keeps the mode, colours and size only', () {
      const ReaderSettings s = ReaderSettings(
        enabled: true,
        theme: ReaderTheme.beige,
        size: 5,
        lineSpacing: 0,
        letterSpacing: 2,
        margin: 4,
        bold: true,
      );

      expect(
        s.resetLayout(),
        const ReaderSettings(enabled: true, theme: ReaderTheme.beige, size: 5),
      );
    });

    test('the tables grow with the step and the defaults are inside them', () {
      for (final List<double> table in <List<double>>[
        readerLineHeights,
        readerLetterSpacings,
        readerMargins,
      ]) {
        for (int i = 1; i < table.length; i++) {
          expect(table[i], greaterThan(table[i - 1]));
        }
      }
      expect(readerDefaultLineSpacing, lessThan(readerLineHeights.length));
      expect(readerDefaultLetterSpacing, lessThan(readerLetterSpacings.length));
      expect(readerDefaultMargin, lessThan(readerMargins.length));
    });

    test('sizes grow with the step', () {
      for (int i = 1; i < readerTextSizes.length; i++) {
        expect(readerTextSizes[i], greaterThan(readerTextSizes[i - 1]));
      }
    });
  });
}
