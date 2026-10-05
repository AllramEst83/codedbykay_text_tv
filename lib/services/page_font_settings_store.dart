import 'package:codedbykay_text_tv/model/page_font_settings.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Keeps the teletext typeface between runs. Like the other stores, neither
/// method throws: unreadable gives the default, unwritable just forgets.
abstract interface class PageFontSettingsStore {
  Future<PageFontSettings> load();
  Future<void> save(PageFontSettings settings);
}

/// [PageFontSettingsStore] in the app's preferences, as one JSON string.
class PrefsPageFontSettingsStore implements PageFontSettingsStore {
  static const String key = 'pageFont';

  @override
  Future<PageFontSettings> load() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      return PageFontSettings.decode(prefs.getString(key));
    } on Object {
      return PageFontSettings.defaults;
    }
  }

  @override
  Future<void> save(PageFontSettings settings) async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString(key, settings.encode());
    } on Object {
      // Forgetting a preference is better than failing the page being read.
    }
  }
}
