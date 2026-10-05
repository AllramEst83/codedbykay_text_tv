import 'package:codedbykay_text_tv/model/language_settings.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Keeps the language setting between runs. Like the other stores, neither
/// method throws: unreadable gives the default, unwritable just forgets.
abstract interface class LanguageSettingsStore {
  Future<LanguageSettings> load();
  Future<void> save(LanguageSettings settings);
}

/// [LanguageSettingsStore] in the app's preferences, as one JSON string.
class PrefsLanguageSettingsStore implements LanguageSettingsStore {
  static const String key = 'language';

  @override
  Future<LanguageSettings> load() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      return LanguageSettings.decode(prefs.getString(key));
    } on Object {
      return LanguageSettings.defaults;
    }
  }

  @override
  Future<void> save(LanguageSettings settings) async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString(key, settings.encode());
    } on Object {
      // Forgetting a preference is better than failing the page being read.
    }
  }
}
