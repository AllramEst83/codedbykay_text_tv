import 'package:codedbykay_text_tv/model/background_settings.dart';
import 'package:codedbykay_text_tv/model/headline_watch.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Keeps the background settings between runs. Like the other stores, neither
/// method throws: unreadable gives the default, unwritable just forgets. The
/// background job reads this too, from its own isolate.
abstract interface class BackgroundSettingsStore {
  Future<BackgroundSettings> load();
  Future<void> save(BackgroundSettings settings);
}

/// [BackgroundSettingsStore] in the app's preferences, as one JSON string.
class PrefsBackgroundSettingsStore implements BackgroundSettingsStore {
  static const String key = 'background';

  @override
  Future<BackgroundSettings> load() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      // The job runs in another isolate: read what is on disk now, not what
      // this isolate cached earlier.
      await prefs.reload();
      return BackgroundSettings.decode(prefs.getString(key));
    } on Object {
      return BackgroundSettings.defaults;
    }
  }

  @override
  Future<void> save(BackgroundSettings settings) async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString(key, settings.encode());
    } on Object {
      // Forgetting a preference is better than failing the page being read.
    }
  }
}

/// Keeps what the alerts last saw, between runs of the background job. Neither
/// method throws: unreadable is "nothing seen yet", unwritable just forgets.
abstract interface class WatchStateStore {
  Future<WatchState> load();
  Future<void> save(WatchState state);
}

/// [WatchStateStore] in the app's preferences, as one JSON string.
class PrefsWatchStateStore implements WatchStateStore {
  static const String key = 'watchState';

  @override
  Future<WatchState> load() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.reload();
      return WatchState.decode(prefs.getString(key));
    } on Object {
      return const WatchState();
    }
  }

  @override
  Future<void> save(WatchState state) async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString(key, state.encode());
    } on Object {
      // Forgetting it means one headline may be announced twice, no worse.
    }
  }
}
