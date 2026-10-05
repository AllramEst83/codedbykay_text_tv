import 'dart:io';

import 'package:codedbykay_text_tv/model/reader_settings.dart';
import 'package:codedbykay_text_tv/ui/theme.dart';
import 'package:flutter_test/flutter_test.dart';

/// The bundled fonts are declared in pubspec.yaml; a typo there would only
/// show on a phone, as the system font standing in, so check it here.
void main() {
  final String pubspec = File('pubspec.yaml').readAsStringSync();

  group('the bundled typefaces', () {
    test('every choice that is not the phone\'s own is declared', () {
      for (final ReaderFont font in ReaderFont.values) {
        if (font == ReaderFont.system) continue;
        expect(pubspec, contains('family: ${readerFontFamily(font)}'));
      }
    });

    test('every file named in pubspec.yaml is there', () {
      final Iterable<RegExpMatch> assets = RegExp(r'asset:\s*(\S+)')
          .allMatches(pubspec);

      expect(assets, isNotEmpty);
      for (final RegExpMatch m in assets) {
        expect(File(m.group(1)!).existsSync(), isTrue, reason: m.group(1));
      }
    });

    test('each font has its licence beside it', () {
      for (final String name in <String>[
        'OFL-PressStart2P.txt',
        'OFL-AtkinsonHyperlegible.txt',
        'OFL-OpenDyslexic.txt',
      ]) {
        final File licence = File('fonts/$name');
        expect(licence.existsSync(), isTrue, reason: name);
        expect(licence.readAsStringSync(), contains('SIL OPEN FONT LICENSE'));
      }
    });

    test('the family names are distinct from the phone\'s', () {
      final Set<String> names = <String>{
        for (final ReaderFont f in ReaderFont.values) readerFontFamily(f),
      };

      expect(names, hasLength(ReaderFont.values.length));
    });
  });
}
