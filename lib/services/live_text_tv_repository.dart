import 'package:codedbykay_text_tv/model/text_tv_page.dart';
import 'package:codedbykay_text_tv/services/network_exception.dart';
import 'package:codedbykay_text_tv/services/page_disk_cache.dart';
import 'package:codedbykay_text_tv/services/text_tv.dart';
import 'package:codedbykay_text_tv/services/text_tv_repository.dart';

DateTime _systemNow() => DateTime.now();

/// [TextTvRepository] on [TextTv], keeping the pages it has read for [maxAge]
/// (the news does not change by the second, and a reader flips back and forth
/// between the same few pages). Only a page that was read is kept; a failure
/// or an unbroadcast page is asked for again. At most [capacity] pages are
/// kept in memory, the longest ago read going first.
///
/// With a [disk] cache every page read is also saved there, as the site sent
/// it. When the site cannot be reached the saved copy is shown instead
/// (marked by [TextTvShown.cachedAt]), and [cached] gives a saved copy at once
/// so a viewer can show it while the current page is read.
class LiveTextTvRepository implements TextTvRepository {
  LiveTextTvRepository({
    required this.textTv,
    this.disk,
    this.maxAge = const Duration(minutes: 5),
    this.capacity = 40,
    this.clock = _systemNow,
  });

  final TextTv textTv;
  final PageDiskCache? disk;
  final Duration maxAge;
  final int capacity;
  final DateTime Function() clock;

  // Insertion order is read order, so the first key is the oldest.
  final Map<int, (TextTvPage, DateTime)> _kept =
      <int, (TextTvPage, DateTime)>{};

  @override
  Future<TextTvResult> page(int number, {bool fresh = false}) async {
    final (TextTvPage, DateTime)? kept = _kept[number];
    if (!fresh && kept != null && clock().difference(kept.$2) < maxAge) {
      return TextTvShown(kept.$1);
    }
    try {
      final String body = await textTv.fetchBody(number);
      final TextTvPage? page = textTv.parse(number, body);
      if (page == null) {
        _kept.remove(number);
        await disk?.remove(number);
        return TextTvNotBroadcast(number);
      }
      final DateTime now = clock();
      _kept.remove(number);
      _kept[number] = (page, now);
      while (_kept.length > capacity) {
        _kept.remove(_kept.keys.first);
      }
      await disk?.write(number, body, now);
      return TextTvShown(page);
    } on NetworkException catch (error) {
      final TextTvShown? saved = await _saved(number);
      if (saved == null) return TextTvFailed(error.message);
      return TextTvShown(saved.page, cachedAt: saved.cachedAt);
    }
  }

  @override
  Future<TextTvShown?> cached(int number) async {
    final (TextTvPage, DateTime)? kept = _kept[number];
    if (kept != null) return TextTvShown(kept.$1);
    final TextTvShown? saved = await _saved(number);
    return saved == null ? null : TextTvShown(saved.page);
  }

  /// The copy on disk, with when it was saved, or null if there is none or it
  /// can no longer be read.
  Future<TextTvShown?> _saved(int number) async {
    final SavedPage? saved = await disk?.read(number);
    if (saved == null) return null;
    try {
      final TextTvPage? page = textTv.parse(number, saved.body);
      return page == null ? null : TextTvShown(page, cachedAt: saved.savedAt);
    } on NetworkException {
      return null;
    }
  }
}
