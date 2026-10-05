import 'package:codedbykay_text_tv/model/reader_settings.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Keeps the reader's settings between runs. Like the session store, neither
/// method throws: unreadable gives the defaults, unwritable just forgets.
abstract interface class ReaderSettingsStore {
  Future<ReaderSettings> load();
  Future<void> save(ReaderSettings settings);
}

/// [ReaderSettingsStore] in the app's preferences, as one JSON string.
class PrefsReaderSettingsStore implements ReaderSettingsStore {
  static const String key = 'reader';

  @override
  Future<ReaderSettings> load() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      return ReaderSettings.decode(prefs.getString(key));
    } on Object {
      return const ReaderSettings();
    }
  }

  @override
  Future<void> save(ReaderSettings settings) async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString(key, settings.encode());
    } on Object {
      // Forgetting a preference is better than failing the page being read.
    }
  }
}
