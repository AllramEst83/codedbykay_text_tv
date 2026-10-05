import 'package:codedbykay_text_tv/model/saved_pages.dart';
import 'package:flutter_test/flutter_test.dart';

List<int> _pages(SavedPages s) =>
    s.favourites.map((Favourite f) => f.page).toList();

void main() {
  group('Favourite', () {
    test('a name is part of its label, a bare page is just its number', () {
      expect(const Favourite(100, 'NYHETER').label, '100 NYHETER');
      expect(const Favourite(377).label, '377');
    });
  });

  group('SavedPages', () {
    test('starts with the six built-in favourites', () {
      expect(_pages(const SavedPages()), <int>[100, 101, 104, 300, 400, 700]);
      expect(defaultFavourites.map((Favourite f) => f.label), <String>[
        '100 NYHETER',
        '101 INRIKES',
        '104 UTRIKES',
        '300 SPORT',
        '400 VÄDER',
        '700 INNEHÅLL',
      ]);
    });

    test('knows which pages are favourites', () {
      const SavedPages s = SavedPages();

      expect(s.isFavourite(300), isTrue);
      expect(s.isFavourite(377), isFalse);
    });

    test('toggling a new page adds it at the end', () {
      final SavedPages s = const SavedPages().toggleFavourite(377);

      expect(_pages(s), <int>[100, 101, 104, 300, 400, 700, 377]);
      expect(s.favourites.last.name, isNull);
      expect(s.isFavourite(377), isTrue);
    });

    test('toggling a favourite removes it, keeping the order of the rest', () {
      final SavedPages s = const SavedPages().toggleFavourite(104);

      expect(_pages(s), <int>[100, 101, 300, 400, 700]);
    });

    test('toggling twice is a round trip, but a built-in loses its name', () {
      final SavedPages added = const SavedPages().toggleFavourite(377);
      expect(_pages(added.toggleFavourite(377)), _pages(const SavedPages()));

      final SavedPages readded = const SavedPages()
          .toggleFavourite(300)
          .toggleFavourite(300);
      expect(readded.favourites.last, const Favourite(300));
    });

    test('everything can be removed', () {
      SavedPages s = const SavedPages();
      for (final Favourite f in defaultFavourites) {
        s = s.toggleFavourite(f.page);
      }

      expect(s.favourites, isEmpty);
    });

    test('a full list takes no more, and says nothing else changed', () {
      SavedPages s = const SavedPages(favourites: <Favourite>[]);
      for (int i = 0; i < SavedPages.maxFavourites; i++) {
        s = s.toggleFavourite(200 + i);
      }
      expect(s.favourites, hasLength(SavedPages.maxFavourites));

      final SavedPages again = s.toggleFavourite(800);

      expect(again, s);
      expect(again.isFavourite(800), isFalse);
      // A page can still be removed from a full list.
      expect(
        s.toggleFavourite(200).favourites,
        hasLength(SavedPages.maxFavourites - 1),
      );
    });

    test('a number that is not a page is ignored', () {
      const SavedPages s = SavedPages();

      expect(s.toggleFavourite(99), s);
      expect(s.toggleFavourite(900), s);
      expect(s.toggleFavourite(-1), s);
    });

    test('resetFavourites brings back the six', () {
      final SavedPages s = const SavedPages(
        favourites: <Favourite>[Favourite(377)],
      );

      expect(s.resetFavourites(), const SavedPages());
    });
  });

  group('SavedPages saved and read back', () {
    test('survives a round trip, names and order and all', () {
      const SavedPages s = SavedPages(
        favourites: <Favourite>[
          Favourite(377),
          Favourite(100, 'NYHETER'),
          Favourite(450),
        ],
      );

      expect(SavedPages.decode(s.encode()), s);
    });

    test('nothing saved is the built-in six', () {
      expect(SavedPages.decode(null), const SavedPages());
    });

    test('nonsense is the built-in six', () {
      for (final String bad in <String>[
        '',
        'x',
        '[]',
        '7',
        '{',
        '{"favourites": 5}',
        '{}',
      ]) {
        expect(SavedPages.decode(bad), const SavedPages(), reason: bad);
      }
    });

    test('an empty list is a reader who removed them all, not a reset', () {
      expect(SavedPages.decode('{"favourites": []}').favourites, isEmpty);
    });

    test('a bad entry is dropped and the good ones kept', () {
      final SavedPages s = SavedPages.decode(
        '{"favourites": [{"page": 377}, 5, {"page": "x"}, {"page": 99}, '
        '{"page": 900}, null, {"name": "A"}, {"page": 400, "name": "VÄDER"}]}',
      );

      expect(s.favourites, <Favourite>[
        const Favourite(377),
        const Favourite(400, 'VÄDER'),
      ]);
    });

    test('a page twice is kept once', () {
      expect(
        _pages(
          SavedPages.decode(
            '{"favourites": [{"page": 377}, {"page": 400}, {"page": 377}]}',
          ),
        ),
        <int>[377, 400],
      );
    });

    test('a name is trimmed, cut short, and dropped if blank', () {
      final SavedPages s = SavedPages.decode(
        '{"favourites": [{"page": 377, "name": "  SPORT  "}, '
        '{"page": 378, "name": "   "}, {"page": 379, "name": 5}, '
        '{"page": 380, "name": "ETT MYCKET LÅNGT NAMN SOM INTE ÄR RIMLIGT"}]}',
      );

      expect(s.favourites[0].name, 'SPORT');
      expect(s.favourites[1].name, isNull);
      expect(s.favourites[2].name, isNull);
      expect(s.favourites[3].name!.length, 16);
    });

    test('no more than the cap are read', () {
      final String many = <String>[
        for (int i = 0; i < SavedPages.maxFavourites + 10; i++)
          '{"page": ${200 + i}}',
      ].join(',');

      expect(
        SavedPages.decode('{"favourites": [$many]}').favourites,
        hasLength(SavedPages.maxFavourites),
      );
    });
  });
}
