import 'dart:ui';

import 'package:codedbykay_text_tv/model/language_settings.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('LanguageSettings', () {
    test('follows the phone until told otherwise', () {
      expect(const LanguageSettings().language, AppLanguage.system);
      expect(LanguageSettings.defaults.language.locale, isNull);
    });

    test('survives a round trip, every language', () {
      for (final AppLanguage language in AppLanguage.values) {
        final LanguageSettings s = LanguageSettings(language: language);

        expect(LanguageSettings.decode(s.encode()), s);
      }
    });

    test('nothing saved, nonsense or an unknown language is the phone\'s', () {
      for (final String? source in <String?>[
        null,
        '',
        'garbage',
        '[]',
        '{"language": "klingon"}',
        '{"language": 3}',
        '{}',
      ]) {
        expect(
          LanguageSettings.decode(source).language,
          AppLanguage.system,
          reason: '$source',
        );
      }
    });

    test('a chosen language is a locale to force', () {
      expect(AppLanguage.swedish.locale, const Locale('sv'));
      expect(AppLanguage.english.locale, const Locale('en'));
    });

    test('equal when the language is', () {
      expect(
        const LanguageSettings(language: AppLanguage.swedish),
        const LanguageSettings(language: AppLanguage.swedish),
      );
      expect(
        const LanguageSettings(language: AppLanguage.swedish).hashCode,
        const LanguageSettings(language: AppLanguage.swedish).hashCode,
      );
      expect(
        const LanguageSettings(language: AppLanguage.swedish),
        isNot(const LanguageSettings()),
      );
    });
  });

  group('resolveLocale', () {
    test('Swedish phones get Swedish, in any region', () {
      expect(resolveLocale(const Locale('sv')), const Locale('sv'));
      expect(resolveLocale(const Locale('sv', 'FI')), const Locale('sv'));
    });

    test('English phones get English', () {
      expect(resolveLocale(const Locale('en', 'GB')), const Locale('en'));
    });

    test('a language the app does not have gets English', () {
      expect(resolveLocale(const Locale('da')), const Locale('en'));
      expect(resolveLocale(const Locale('ja')), const Locale('en'));
      expect(resolveLocale(null), const Locale('en'));
    });
  });
}
