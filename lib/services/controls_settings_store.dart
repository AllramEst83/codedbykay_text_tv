import 'package:codedbykay_text_tv/model/controls_settings.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Keeps the controls setting between runs. Like the other stores, neither
/// method throws: unreadable gives the default, unwritable just forgets.
abstract interface class ControlsSettingsStore {
  Future<ControlsSettings> load();
  Future<void> save(ControlsSettings settings);
}

/// [ControlsSettingsStore] in the app's preferences, as one JSON string.
class PrefsControlsSettingsStore implements ControlsSettingsStore {
  static const String key = 'controls';

  @override
  Future<ControlsSettings> load() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      return ControlsSettings.decode(prefs.getString(key));
    } on Object {
      return ControlsSettings.defaults;
    }
  }

  @override
  Future<void> save(ControlsSettings settings) async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString(key, settings.encode());
    } on Object {
      // Forgetting a preference is better than failing the page being read.
    }
  }
}
