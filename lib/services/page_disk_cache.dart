import 'dart:io';

/// A page's raw answer as it was kept, and when.
class SavedPage {
  const SavedPage(this.body, this.savedAt);

  final String body;
  final DateTime savedAt;
}

/// Pages kept between runs, so one read a while ago can still be shown with no
/// network. No method throws: a cache that fails is a cache that has nothing.
abstract interface class PageDiskCache {
  Future<SavedPage?> read(int number);
  Future<void> write(int number, String body, DateTime at);
  Future<void> remove(int number);
}

/// [PageDiskCache] as one file per page in [directory], named `<number>.json`,
/// holding the answer as the site sent it. The file's modified time is the time
/// it was saved. At most [capacity] pages are kept, the longest ago saved going
/// first.
class FilePageDiskCache implements PageDiskCache {
  FilePageDiskCache(this.directory, {this.capacity = 200});

  final Directory directory;
  final int capacity;

  File _file(int number) => File('${directory.path}/$number.json');

  @override
  Future<SavedPage?> read(int number) async {
    try {
      final File file = _file(number);
      return SavedPage(await file.readAsString(), await file.lastModified());
    } on Object {
      return null;
    }
  }

  @override
  Future<void> write(int number, String body, DateTime at) async {
    try {
      await directory.create(recursive: true);
      // Written beside the page and renamed into place, so a reader never
      // meets half an answer.
      final File temp = File('${directory.path}/$number.tmp');
      await temp.writeAsString(body, flush: true);
      await temp.setLastModified(at);
      await temp.rename(_file(number).path);
      await _evict();
    } on Object {
      // Not keeping a page is better than failing the one being read.
    }
  }

  @override
  Future<void> remove(int number) async {
    try {
      await _file(number).delete();
    } on Object {
      // Already gone, or cannot be: either way there is nothing to serve.
    }
  }

  Future<void> _evict() async {
    final List<(File, DateTime)> pages = <(File, DateTime)>[
      for (final FileSystemEntity entity in directory.listSync())
        if (entity is File && entity.path.endsWith('.json'))
          (entity, entity.lastModifiedSync()),
    ];
    if (pages.length <= capacity) return;
    pages.sort(
      ((File, DateTime) a, (File, DateTime) b) => a.$2.compareTo(b.$2),
    );
    for (final (File file, _) in pages.take(pages.length - capacity)) {
      await file.delete();
    }
  }
}
