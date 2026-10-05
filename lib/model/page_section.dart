/// The pages most people open, which have a name of their own: the built-in
/// favourites. What each is called is up to the language (see `chipLabel`).
enum PageSection { news, domestic, world, sport, weather, contents }

/// The section whose page number is [page], or null for any other page.
PageSection? sectionOf(int page) => switch (page) {
  100 => PageSection.news,
  101 => PageSection.domestic,
  104 => PageSection.world,
  300 => PageSection.sport,
  400 => PageSection.weather,
  700 => PageSection.contents,
  _ => null,
};

/// What the first built-in favourites were called before they were named by
/// language: a saved list that still has these on them has the built-in names,
/// not names the reader chose.
const Map<int, String> legacyDefaultNames = <int, String>{
  100: 'NYHETER',
  101: 'INRIKES',
  104: 'UTRIKES',
  300: 'SPORT',
  400: 'VÄDER',
  700: 'INNEHÅLL',
};
