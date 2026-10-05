import 'package:codedbykay_text_tv/model/text_tv_session.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Keeps the reader's place between runs. Neither method throws: a store that
/// cannot be read gives the default session, and one that cannot be written
/// just forgets, because losing the place must never break reading.
abstract interface class SessionStore {
  Future<TextTvSession> load();
  Future<void> save(TextTvSession session);
}

/// [SessionStore] in the app's preferences, as one JSON string.
class PrefsSessionStore implements SessionStore {
  static const String key = 'session';

  @override
  Future<TextTvSession> load() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      return TextTvSession.decode(prefs.getString(key));
    } on Object {
      return const TextTvSession();
    }
  }

  @override
  Future<void> save(TextTvSession session) async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString(key, session.encode());
    } on Object {
      // Forgetting the place is better than failing the page being read.
    }
  }
}
