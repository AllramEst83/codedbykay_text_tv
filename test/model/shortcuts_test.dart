import 'package:codedbykay_text_tv/model/saved_pages.dart';
import 'package:codedbykay_text_tv/model/shortcuts.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('shortcutsFor', () {
    test('the first four favourites, in order, as page:N', () {
      final List<ShortcutEntry> entries = shortcutsFor(defaultFavourites);

      expect(entries.map((ShortcutEntry e) => e.type), <String>[
        'page:100',
        'page:101',
        'page:104',
        'page:300',
      ]);
      expect(maxShortcuts, 4);
    });

    test('a named favourite reads its label, a bare page reads Page N', () {
      final List<ShortcutEntry> entries = shortcutsFor(const <Favourite>[
        Favourite(100, 'NYHETER'),
        Favourite(377),
      ]);

      expect(entries[0].title, '100 NYHETER');
      expect(entries[1].title, 'Page 377');
    });

    test('fewer than four favourites gives fewer shortcuts', () {
      expect(shortcutsFor(const <Favourite>[Favourite(377)]), hasLength(1));
    });

    test('no favourites gives no shortcuts', () {
      expect(shortcutsFor(const <Favourite>[]), isEmpty);
    });

    test('never more than the phone will take, however many favourites', () {
      final List<Favourite> many = <Favourite>[
        for (int i = 0; i < 24; i++) Favourite(200 + i),
      ];

      expect(shortcutsFor(many), hasLength(maxShortcuts));
      expect(shortcutsFor(many).first.type, 'page:200');
    });

    test('entries with the same type and title are equal', () {
      expect(
        const ShortcutEntry('page:100', 'x'),
        const ShortcutEntry('page:100', 'x'),
      );
      expect(
        const ShortcutEntry('page:100', 'x').hashCode,
        const ShortcutEntry('page:100', 'x').hashCode,
      );
      expect(
        const ShortcutEntry('page:100', 'x'),
        isNot(const ShortcutEntry('page:101', 'x')),
      );
    });
  });

  group('pageOfShortcut', () {
    test('reads the page back from what shortcutsFor made', () {
      for (final ShortcutEntry e in shortcutsFor(defaultFavourites)) {
        expect(pageOfShortcut(e.type), int.parse(e.type.split(':').last));
      }
    });

    test('anything that is not a page of ours is not a page', () {
      for (final String type in <String>[
        '',
        'page:',
        'page:abc',
        'page:99',
        'page:900',
        'page:-1',
        'page:3.5',
        'other:300',
        'action_one',
        'PAGE:300',
        ' page:300',
      ]) {
        expect(pageOfShortcut(type), isNull, reason: type);
      }
    });

    test('the ends of the range are pages', () {
      expect(pageOfShortcut('page:100'), 100);
      expect(pageOfShortcut('page:899'), 899);
    });
  });
}
