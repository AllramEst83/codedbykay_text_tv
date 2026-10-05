import 'package:codedbykay_text_tv/model/saved_pages.dart';
import 'package:codedbykay_text_tv/services/saved_pages_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues(<String, Object>{}));

  group('PrefsSavedPagesStore', () {
    test('a first run gets the built-in favourites', () async {
      expect(await PrefsSavedPagesStore().load(), const SavedPages());
    });

    test('gives back what was saved, to a new store too', () async {
      const SavedPages saved = SavedPages(
        favourites: <Favourite>[Favourite(377), Favourite(100, 'NYHETER')],
      );

      await PrefsSavedPagesStore().save(saved);

      expect(await PrefsSavedPagesStore().load(), saved);
    });

    test('the recent pages come back too, in order', () async {
      final SavedPages saved = const SavedPages().visited(300).visited(377);

      await PrefsSavedPagesStore().save(saved);

      expect((await PrefsSavedPagesStore().load()).recents, <int>[377, 300]);
    });

    test('a reader who removed them all gets none, not the six', () async {
      await PrefsSavedPagesStore().save(
        const SavedPages(favourites: <Favourite>[]),
      );

      expect((await PrefsSavedPagesStore().load()).favourites, isEmpty);
    });

    test('a damaged saved value gives the built-in favourites', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{
        PrefsSavedPagesStore.key: 'garbage',
      });

      expect(await PrefsSavedPagesStore().load(), const SavedPages());
    });
  });
}
