import 'dart:typed_data';

import 'package:share_plus/share_plus.dart';

/// The phone's share sheet, as little as it can be. [SharePlusPlatform] is the
/// real one; tests use a fake.
abstract interface class SharePlatform {
  /// Opens the share sheet with [text]. Never throws: a phone that cannot
  /// share just does not.
  Future<void> shareText(String text, {String? subject});

  /// Opens the share sheet with the PNG [png], called [name], and [text] with
  /// it. Never throws.
  Future<void> shareImage(Uint8List png, {required String name, String? text});
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

  @override
  Future<void> shareImage(
    Uint8List png, {
    required String name,
    String? text,
  }) async {
    try {
      await SharePlus.instance.share(
        ShareParams(
          files: <XFile>[XFile.fromData(png, mimeType: 'image/png')],
          fileNameOverrides: <String>[name],
          text: text,
        ),
      );
    } on Object {
      // No share sheet: nothing to do.
    }
  }
}
