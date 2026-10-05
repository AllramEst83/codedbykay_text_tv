import 'package:codedbykay_text_tv/model/text_tv_session.dart';
import 'package:codedbykay_text_tv/services/session_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues(<String, Object>{}));

  group('PrefsSessionStore', () {
    test('a first run gets the default session', () async {
      expect(await PrefsSessionStore().load(), const TextTvSession());
    });

    test('gives back what was saved, to a new store too', () async {
      const TextTvSession session = TextTvSession(
        page: 377,
        part: 1,
        history: <int>[100, 300],
      );

      await PrefsSessionStore().save(session);

      expect(await PrefsSessionStore().load(), session);
    });

    test('a later save replaces the earlier one', () async {
      final PrefsSessionStore store = PrefsSessionStore();
      await store.save(const TextTvSession(page: 300));
      await store.save(const TextTvSession(page: 400));

      expect(await store.load(), const TextTvSession(page: 400));
    });

    test('a damaged saved value gives the default session', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{
        PrefsSessionStore.key: 'garbage',
      });

      expect(await PrefsSessionStore().load(), const TextTvSession());
    });
  });
}
