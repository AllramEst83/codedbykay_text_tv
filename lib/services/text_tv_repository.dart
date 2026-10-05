import 'package:codedbykay_text_tv/model/text_tv_page.dart';

/// Text TV pages for the viewer. Never throws: every
/// failure is a [TextTvResult] that says why.
abstract interface class TextTvRepository {
  /// Page [number] (100 to 899). A page read a few minutes ago may be reused
  /// (going back to a page just left must not fetch it again); [fresh]
  /// insists on asking the site.
  Future<TextTvResult> page(int number, {bool fresh = false});

  /// The newest copy already held for [number] (in memory or saved on disk),
  /// however old, or null. Quick: it never asks the site, so a viewer can show
  /// it while [page] reads the current one.
  Future<TextTvShown?> cached(int number);
}
