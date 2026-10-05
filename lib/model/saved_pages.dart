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

/// The pages the reader has chosen to keep, in the order they chose them, and
/// the ones they read last. Read from disk, so decoding is tolerant: a bad
/// entry is dropped, never the rest.
class SavedPages {
  const SavedPages({
    this.favourites = defaultFavourites,
    this.recents = const <int>[],
  });

  /// Room for this many favourites: a row of chips that scrolls sideways is
  /// fine for a couple of dozen and unusable for hundreds.
  static const int maxFavourites = 24;

  /// The most pages remembered as recent.
  static const int maxRecents = 12;

  final List<Favourite> favourites;

  /// The pages read last, the latest first, each once.
  final List<int> recents;

  /// Whether the favourites are just the built-in six, in their order.
  bool get hasDefaultFavourites =>
      favourites.length == defaultFavourites.length &&
      Iterable<int>.generate(favourites.length)
          .every((int i) => favourites[i] == defaultFavourites[i]);

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
        recents: recents,
      );
    }
    if (favourites.length >= maxFavourites) return this;
    return SavedPages(
      favourites: <Favourite>[...favourites, Favourite(page)],
      recents: recents,
    );
  }

  /// The favourites put back to the built-in six; the recent pages stay.
  SavedPages resetFavourites() => SavedPages(recents: recents);

  /// [page] read now: first among the recent pages, wherever it was before,
  /// and the oldest dropped past [maxRecents]. A number that is not a page is
  /// ignored.
  SavedPages visited(int page) {
    if (page < textTvFirstPage || page > textTvLastPage) return this;
    if (recents.isNotEmpty && recents.first == page) return this;
    return SavedPages(
      favourites: favourites,
      recents: <int>[
        page,
        for (final int r in recents)
          if (r != page) r,
      ].take(maxRecents).toList(),
    );
  }

  /// No recent pages; the favourites stay.
  SavedPages clearRecents() => SavedPages(favourites: favourites);

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
    final Object? seen = json['recents'];
    final List<int> recents = <int>[];
    if (seen is List) {
      for (final Object? entry in seen) {
        if (entry is! int ||
            entry < textTvFirstPage ||
            entry > textTvLastPage) {
          continue;
        }
        if (!recents.contains(entry)) recents.add(entry);
        if (recents.length >= maxRecents) break;
      }
    }
    if (list is! List) return SavedPages(recents: recents);
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
    return SavedPages(favourites: favourites, recents: recents);
  }

  String encode() => jsonEncode(<String, Object?>{
    'favourites': <Object?>[
      for (final Favourite f in favourites)
        <String, Object?>{'page': f.page, if (f.name != null) 'name': f.name},
    ],
    'recents': recents,
  });

  @override
  bool operator ==(Object other) =>
      other is SavedPages &&
      other.favourites.length == favourites.length &&
      Iterable<int>.generate(favourites.length)
          .every((int i) => other.favourites[i] == favourites[i]) &&
      other.recents.length == recents.length &&
      Iterable<int>.generate(recents.length)
          .every((int i) => other.recents[i] == recents[i]);

  @override
  int get hashCode =>
      Object.hash(Object.hashAll(favourites), Object.hashAll(recents));
}
