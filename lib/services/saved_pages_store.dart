import 'package:codedbykay_text_tv/model/saved_pages.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Keeps the reader's favourite pages between runs. Like the other stores,
/// neither method throws: unreadable gives the built-in favourites,
/// unwritable just forgets.
abstract interface class SavedPagesStore {
  Future<SavedPages> load();
  Future<void> save(SavedPages pages);
}

/// [SavedPagesStore] in the app's preferences, as one JSON string.
class PrefsSavedPagesStore implements SavedPagesStore {
  static const String key = 'pages';

  @override
  Future<SavedPages> load() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      return SavedPages.decode(prefs.getString(key));
    } on Object {
      return const SavedPages();
    }
  }

  @override
  Future<void> save(SavedPages pages) async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString(key, pages.encode());
    } on Object {
      // Forgetting a preference is better than failing the page being read.
    }
  }
}
