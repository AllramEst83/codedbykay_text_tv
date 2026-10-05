import 'package:share_plus/share_plus.dart';

/// The phone's share sheet, as little as it can be. [SharePlusPlatform] is the
/// real one; tests use a fake.
abstract interface class SharePlatform {
  /// Opens the share sheet with [text]. Never throws: a phone that cannot
  /// share just does not.
  Future<void> shareText(String text, {String? subject});
}

/// [SharePlatform] on the `share_plus` plugin.
class SharePlusPlatform implements SharePlatform {
  const SharePlusPlatform();

  @override
  Future<void> shareText(String text, {String? subject}) async {
    try {
      await SharePlus.instance.share(ShareParams(text: text, subject: subject));
    } on Object {
      // No share sheet: nothing to do.
    }
  }
}
