import 'package:codedbykay_text_tv/model/page_font_settings.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PageFontSettings', () {
    test('starts on the pixel face the app began with', () {
      expect(const PageFontSettings().font, PageFont.pixel);
      expect(PageFontSettings.defaults.font, PageFont.pixel);
    });

    test('survives a round trip, every font', () {
      for (final PageFont font in PageFont.values) {
        final PageFontSettings s = PageFontSettings(font: font);

        expect(PageFontSettings.decode(s.encode()), s);
      }
    });

    test('nothing saved, nonsense or an unknown font is the pixel face', () {
      for (final String? source in <String?>[
        null,
        '',
        'garbage',
        '[]',
        '{"font": "comic"}',
        '{"font": 2}',
        '{}',
      ]) {
        expect(
          PageFontSettings.decode(source).font,
          PageFont.pixel,
          reason: '$source',
        );
      }
    });

    test('equal when the font is', () {
      expect(
        const PageFontSettings(font: PageFont.bedstead),
        const PageFontSettings(font: PageFont.bedstead),
      );
      expect(
        const PageFontSettings(font: PageFont.bedstead),
        isNot(const PageFontSettings()),
      );
      expect(
        const PageFontSettings(font: PageFont.bedstead).hashCode,
        isNot(const PageFontSettings().hashCode),
      );
    });
  });
}
