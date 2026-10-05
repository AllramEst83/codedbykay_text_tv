import 'package:codedbykay_text_tv/model/saved_pages.dart';
import 'package:codedbykay_text_tv/services/shortcut_service.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fakes/fake_shortcut_platform.dart';

void main() {
  late FakeShortcutPlatform platform;
  late ShortcutService service;
  setUp(() {
    platform = FakeShortcutPlatform();
    service = ShortcutService(platform);
  });
  tearDown(() => service.dispose());

  group('ShortcutService', () {
    test('starting listens to the platform, once', () async {
      await service.start();

      expect(platform.starts, 1);
    });

    test(
      'update gives the platform the first favourites as shortcuts',
      () async {
        await service.update(defaultFavourites);

        expect(platform.current.map((e) => e.type), <String>[
          'page:100',
          'page:101',
          'page:104',
          'page:300',
        ]);
      },
    );

    test('update replaces what was there, and can empty it', () async {
      await service.update(defaultFavourites);
      await service.update(const <Favourite>[Favourite(377)]);
      expect(platform.current.map((e) => e.type), <String>['page:377']);

      await service.update(const <Favourite>[]);
      expect(platform.current, isEmpty);
      expect(platform.sets, hasLength(3));
    });

    test('a page chosen from the icon comes out of opened', () async {
      await service.start();
      final List<int> heard = <int>[];
      service.opened.listen(heard.add);

      platform.choose('page:377');
      platform.choose('page:104');
      await Future<void>.delayed(Duration.zero);

      expect(heard, <int>[377, 104]);
    });

    test('a shortcut that started the app is kept for the screen that listens later', () async {
      await service.start();

      platform.choose('page:450');
      final List<int> heard = <int>[];
      service.opened.listen(heard.add);
      await Future<void>.delayed(Duration.zero);

      expect(heard, <int>[450]);
    });

    test('something that is not a page of ours is ignored', () async {
      await service.start();
      final List<int> heard = <int>[];
      service.opened.listen(heard.add);

      platform.choose('page:99');
      platform.choose('nonsense');
      platform.choose('page:300');
      await Future<void>.delayed(Duration.zero);

      expect(heard, <int>[300]);
    });

    test('a phone that cannot do shortcuts is no trouble', () async {
      platform.failing = true;

      await expectLater(service.start(), completes);
      await expectLater(service.update(defaultFavourites), completes);
    });

    test(
      'nothing is heard after it is closed, and closing twice is fine',
      () async {
        await service.start();
        await service.dispose();

        expect(() => platform.choose('page:300'), returnsNormally);
        await expectLater(service.dispose(), completes);
      },
    );
  });
}
