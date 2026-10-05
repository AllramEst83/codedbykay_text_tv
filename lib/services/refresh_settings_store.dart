import 'package:codedbykay_text_tv/model/refresh_settings.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Keeps the refresh setting between runs. Like the other stores, neither
/// method throws: unreadable gives the default, unwritable just forgets.
abstract interface class RefreshSettingsStore {
  Future<RefreshSettings> load();
  Future<void> save(RefreshSettings settings);
}

/// [RefreshSettingsStore] in the app's preferences, as one JSON string.
class PrefsRefreshSettingsStore implements RefreshSettingsStore {
  static const String key = 'refresh';

  @override
  Future<RefreshSettings> load() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      return RefreshSettings.decode(prefs.getString(key));
    } on Object {
      return const RefreshSettings();
    }
  }

  @override
  Future<void> save(RefreshSettings settings) async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString(key, settings.encode());
    } on Object {
      // Forgetting a preference is better than failing the page being read.
    }
  }
}
