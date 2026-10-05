import 'package:codedbykay_text_tv/model/saved_pages.dart';
import 'package:codedbykay_text_tv/model/text_tv_page.dart';

/// Android shows only a few shortcuts when the app icon is pressed and
/// refuses to be given more than its limit (often four or five), so only the
/// first four favourites are offered.
const int maxShortcuts = 4;

/// One entry for the app icon's long-press menu: what it is and what it says.
class ShortcutEntry {
  const ShortcutEntry(this.type, this.title);

  /// What the system hands back when it is chosen: `page:377`.
  final String type;
  final String title;

  @override
  bool operator ==(Object other) =>
      other is ShortcutEntry && other.type == type && other.title == title;

  @override
  int get hashCode => Object.hash(type, title);
}

const String _prefix = 'page:';

/// The entries for the first [maxShortcuts] of [favourites], in order, each
/// saying what [title] makes of the favourite (by default `100 NYHETER` for a
/// named one, `Page 377` for one with only a number: the app says it in the
/// language of the phone, see `shortcutTitle`).
List<ShortcutEntry> shortcutsFor(
  List<Favourite> favourites, {
  String Function(Favourite favourite) title = _plainTitle,
}) => <ShortcutEntry>[
  for (final Favourite f in favourites.take(maxShortcuts))
    ShortcutEntry('$_prefix${f.page}', title(f)),
];

String _plainTitle(Favourite f) => f.name == null ? 'Page ${f.page}' : f.label;

/// The page a chosen shortcut stands for, or null for anything that is not one
/// of ours or not a page (a stale shortcut from an older version, say).
int? pageOfShortcut(String type) {
  if (!type.startsWith(_prefix)) return null;
  final int? page = int.tryParse(type.substring(_prefix.length));
  if (page == null || page < textTvFirstPage || page > textTvLastPage) {
    return null;
  }
  return page;
}
