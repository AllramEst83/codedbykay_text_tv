import 'dart:convert';
import 'dart:io';

import 'package:codedbykay_text_tv/l10n/app_localizations_sv.dart';
import 'package:codedbykay_text_tv/model/network_failure.dart';
import 'package:codedbykay_text_tv/model/reader_settings.dart';
import 'package:codedbykay_text_tv/model/saved_pages.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fakes/english.dart';

Map<String, Object?> _arb(String locale) =>
    jsonDecode(File('lib/l10n/app_$locale.arb').readAsStringSync())
        as Map<String, Object?>;

Iterable<String> _keys(Map<String, Object?> arb) =>
    arb.keys.where((String k) => !k.startsWith('@'));

final RegExp _placeholder = RegExp(r'\{(\w+)\}');

Set<String> _placeholders(Object? text) => <String>{
  for (final RegExpMatch m in _placeholder.allMatches('$text')) m.group(1)!,
};

void main() {
  final Map<String, Object?> english = _arb('en');
  final Map<String, Object?> swedish = _arb('sv');
  final AppLocalizations sv = AppLocalizationsSv();

  group('the translations', () {
    test('Swedish has every string English has, and no others', () {
      expect(_keys(swedish).toSet(), _keys(english).toSet());
    });

    test('every string says something', () {
      for (final Map<String, Object?> arb in <Map<String, Object?>>[
        english,
        swedish,
      ]) {
        for (final String key in _keys(arb)) {
          if (key.startsWith('@')) continue;
          expect('${arb[key]}'.trim(), isNotEmpty, reason: key);
        }
      }
    });

    test('a string has the same blanks to fill in either language', () {
      for (final String key in _keys(english)) {
        if (key == '@@locale') continue;
        expect(
          _placeholders(swedish[key]),
          _placeholders(english[key]),
          reason: key,
        );
      }
    });

    test('a Swedish string is not left as the English one', () {
      // Words that are the same in both languages, and the names.
      const Set<String> same = <String>{
        'sectionSport',
        'themeBeige',
        'fontSystem',
        'fontAtkinson',
        'fontDyslexic',
        'autoRefreshSeconds',
        'autoRefreshMinutes',
      };
      for (final String key in _keys(english)) {
        if (key == '@@locale' || same.contains(key)) continue;
        expect(swedish[key], isNot(english[key]), reason: key);
      }
    });
  });

  group('the wording that is a choice', () {
    test('every failure has words in both languages', () {
      for (final NetworkFailure f in NetworkFailure.values) {
        expect(en.failure(f), isNotEmpty);
        expect(sv.failure(f), isNotEmpty);
        expect(sv.failure(f), isNot(en.failure(f)));
      }
    });

    test('every reader theme is named in both languages', () {
      for (final ReaderTheme t in ReaderTheme.values) {
        expect(en.themeName(t), isNotEmpty);
        expect(sv.themeName(t), isNotEmpty);
      }
    });

    test('the refresh step reads off, seconds or minutes', () {
      expect(en.autoRefreshValue(null), 'OFF');
      expect(sv.autoRefreshValue(null), 'AV');
      expect(en.autoRefreshValue(const Duration(seconds: 30)), '30 S');
      expect(en.autoRefreshValue(const Duration(minutes: 2)), '2 MIN');
    });

    test(
      'a chip names the built-in pages in the language, others by number',
      () {
        expect(en.chipLabel(const Favourite(100)), '100 NEWS');
        expect(sv.chipLabel(const Favourite(100)), '100 NYHETER');
        expect(sv.chipLabel(const Favourite(400)), '400 VÄDER');
        expect(sv.chipLabel(const Favourite(700)), '700 INNEHÅLL');
        expect(sv.chipLabel(const Favourite(377)), '377');
        expect(sv.chipLabel(const Favourite(377, 'MINA')), '377 MINA');
      },
    );

    test('an icon shortcut says the same, or Page / Sida for the rest', () {
      expect(en.shortcutTitle(const Favourite(104)), '104 WORLD');
      expect(sv.shortcutTitle(const Favourite(104)), '104 UTRIKES');
      expect(en.shortcutTitle(const Favourite(377)), 'Page 377');
      expect(sv.shortcutTitle(const Favourite(377)), 'Sida 377');
    });

    test('the blanks are filled', () {
      expect(sv.favouritesCount(3, 24), '3 AV 24 SPARADE');
      expect(sv.pageNotBroadcast(555), 'SIDA 555 SÄNDS INTE.');
      expect(en.updated('14:32'), 'UPDATED 14:32');
      expect(sv.updated('14:32'), 'UPPDATERAD 14:32');
    });
  });
}
