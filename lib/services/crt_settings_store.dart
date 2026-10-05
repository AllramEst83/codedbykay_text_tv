import 'package:codedbykay_text_tv/model/crt_settings.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Keeps the CRT look between runs. Like the other stores, neither method
/// throws: unreadable gives the defaults, unwritable just forgets.
abstract interface class CrtSettingsStore {
  Future<CrtSettings> load();
  Future<void> save(CrtSettings settings);
}

/// [CrtSettingsStore] in the app's preferences, as one JSON string.
class PrefsCrtSettingsStore implements CrtSettingsStore {
  static const String key = 'crt';

  @override
  Future<CrtSettings> load() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      return CrtSettings.decode(prefs.getString(key));
    } on Object {
      return CrtSettings.defaults;
    }
  }

  @override
  Future<void> save(CrtSettings settings) async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString(key, settings.encode());
    } on Object {
      // Forgetting a preference is better than failing the page being read.
    }
  }
}
