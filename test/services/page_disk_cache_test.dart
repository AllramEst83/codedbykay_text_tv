import 'dart:io';

import 'package:codedbykay_text_tv/services/page_disk_cache.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late Directory root;
  late Directory directory;
  setUp(() {
    root = Directory.systemTemp.createTempSync('page_disk_cache_test');
    directory = Directory('${root.path}/pages');
  });
  tearDown(() => root.deleteSync(recursive: true));

  final DateTime t0 = DateTime(2026, 10, 5, 12);

  group('FilePageDiskCache', () {
    test('gives back what was written, and when', () async {
      final FilePageDiskCache cache = FilePageDiskCache(directory);

      await cache.write(377, '{"a": "Åäö"}', t0);
      final SavedPage? saved = await cache.read(377);

      expect(saved, isNotNull);
      expect(saved!.body, '{"a": "Åäö"}');
      expect(saved.savedAt.difference(t0).abs().inSeconds, lessThan(2));
    });

    test(
      'a page never written, or a folder that does not exist, is null',
      () async {
        expect(await FilePageDiskCache(directory).read(100), isNull);

        await FilePageDiskCache(directory).write(101, 'x', t0);
        expect(await FilePageDiskCache(directory).read(100), isNull);
      },
    );

    test(
      'numbers lists the pages kept, and nothing for a missing folder',
      () async {
        final FilePageDiskCache cache = FilePageDiskCache(directory);
        expect(await cache.numbers(), isEmpty);

        await cache.write(377, 'x', t0);
        await cache.write(100, 'x', t0);

        expect((await cache.numbers())..sort(), <int>[100, 377]);
      },
    );

    test('a later write replaces the earlier one', () async {
      final FilePageDiskCache cache = FilePageDiskCache(directory);
      await cache.write(100, 'old', t0);
      await cache.write(100, 'new', t0.add(const Duration(minutes: 1)));

      expect((await cache.read(100))!.body, 'new');
    });

    test(
      'remove forgets the page, and removing a missing one is fine',
      () async {
        final FilePageDiskCache cache = FilePageDiskCache(directory);
        await cache.write(100, 'x', t0);

        await cache.remove(100);
        await cache.remove(100);

        expect(await cache.read(100), isNull);
      },
    );

    test('leaves no half-written file behind', () async {
      final FilePageDiskCache cache = FilePageDiskCache(directory);
      await cache.write(100, 'x', t0);

      final List<String> names = <String>[
        for (final FileSystemEntity e in directory.listSync())
          e.path.split(RegExp(r'[\\/]')).last,
      ];
      expect(names, <String>['100.json']);
    });

    test('keeps the most recently saved pages when over capacity', () async {
      final FilePageDiskCache cache = FilePageDiskCache(directory, capacity: 3);
      for (int i = 0; i < 5; i++) {
        await cache.write(100 + i, 'page $i', t0.add(Duration(minutes: i)));
      }

      expect(await cache.read(100), isNull);
      expect(await cache.read(101), isNull);
      for (final int n in <int>[102, 103, 104]) {
        expect(await cache.read(n), isNotNull, reason: '$n');
      }
    });

    test('never throws, even when the folder cannot be made', () async {
      final File blocker = File('${root.path}/blocker')..writeAsStringSync('');
      final FilePageDiskCache cache = FilePageDiskCache(
        Directory('${blocker.path}/pages'),
      );

      await cache.write(100, 'x', t0);
      await cache.remove(100);

      expect(await cache.read(100), isNull);
    });
  });
}
