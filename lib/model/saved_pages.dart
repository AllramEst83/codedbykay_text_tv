import 'dart:convert';

import 'package:codedbykay_text_tv/model/text_tv_page.dart';

/// A page the reader keeps close at hand: its number, and a short name when it
/// has one (the built-in ones do; a page starred from the viewer is just its
/// number).
class Favourite {
  const Favourite(this.page, [this.name]);

  final int page;
  final String? name;

  /// What a chip says: `100 NYHETER`, or just `377`.
  String get label => name == null ? '$page' : '$page $name';

  @override
  bool operator ==(Object other) =>
      other is Favourite && other.page == page && other.name == name;

  @override
  int get hashCode => Object.hash(page, name);
}

/// What a fresh install has: the six pages most people open, which used to be
/// the fixed row of shortcuts.
const List<Favourite> defaultFavourites = <Favourite>[
  Favourite(100, 'NYHETER'),
  Favourite(101, 'INRIKES'),
  Favourite(104, 'UTRIKES'),
  Favourite(300, 'SPORT'),
  Favourite(400, 'VÄDER'),
  Favourite(700, 'INNEHÅLL'),
];

/// The pages the reader has chosen to keep, in the order they chose them. Read
/// from disk, so decoding is tolerant: a bad entry is dropped, never the rest.
class SavedPages {
  const SavedPages({this.favourites = defaultFavourites});

  /// Room for this many favourites: a row of chips that scrolls sideways is
  /// fine for a couple of dozen and unusable for hundreds.
  static const int maxFavourites = 24;

  final List<Favourite> favourites;

  bool isFavourite(int page) => favourites.any((Favourite f) => f.page == page);

  /// Stars [page] if it is not a favourite, adds it at the end, and unstars it
  /// if it is. When the list is full a page is not added (nothing else is
  /// changed): the reader has to remove one first.
  SavedPages toggleFavourite(int page) {
    if (page < textTvFirstPage || page > textTvLastPage) return this;
    if (isFavourite(page)) {
      return SavedPages(
        favourites: <Favourite>[
          for (final Favourite f in favourites)
            if (f.page != page) f,
        ],
      );
    }
    if (favourites.length >= maxFavourites) return this;
    return SavedPages(favourites: <Favourite>[...favourites, Favourite(page)]);
  }

  /// The favourites put back to the built-in six.
  SavedPages resetFavourites() => const SavedPages();

  factory SavedPages.decode(String? source) {
    if (source == null) return const SavedPages();
    final Object? json;
    try {
      json = jsonDecode(source);
    } on FormatException {
      return const SavedPages();
    }
    if (json is! Map<String, Object?>) return const SavedPages();
    final Object? list = json['favourites'];
    // Nothing saved is the built-in six; an empty list is a reader who
    // removed them all.
    if (list is! List) return const SavedPages();
    final List<Favourite> favourites = <Favourite>[];
    for (final Object? entry in list) {
      if (entry is! Map<String, Object?>) continue;
      final Object? page = entry['page'];
      if (page is! int || page < textTvFirstPage || page > textTvLastPage) {
        continue;
      }
      if (favourites.any((Favourite f) => f.page == page)) continue;
      final Object? name = entry['name'];
      final String? trimmed = name is String ? name.trim() : null;
      favourites.add(
        Favourite(
          page,
          trimmed == null || trimmed.isEmpty
              ? null
              : trimmed.substring(0, trimmed.length.clamp(0, 16)),
        ),
      );
      if (favourites.length >= maxFavourites) break;
    }
    return SavedPages(favourites: favourites);
  }

  String encode() => jsonEncode(<String, Object?>{
    'favourites': <Object?>[
      for (final Favourite f in favourites)
        <String, Object?>{'page': f.page, if (f.name != null) 'name': f.name},
    ],
  });

  @override
  bool operator ==(Object other) =>
      other is SavedPages &&
      other.favourites.length == favourites.length &&
      Iterable<int>.generate(favourites.length)
          .every((int i) => other.favourites[i] == favourites[i]);

  @override
  int get hashCode => Object.hashAll(favourites);
}
