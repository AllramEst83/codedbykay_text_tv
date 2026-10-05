import 'dart:typed_data';

import 'package:codedbykay_text_tv/services/share_service.dart';

/// The share sheet, in memory: records what it was asked to share.
class FakeSharePlatform implements SharePlatform {
  /// Every `(text, subject)` shared, in order.
  final List<(String, String?)> texts = <(String, String?)>[];

  /// Every `(png, name, text)` shared, in order.
  final List<(Uint8List, String, String?)> images =
      <(Uint8List, String, String?)>[];

  @override
  Future<void> shareImage(
    Uint8List png, {
    required String name,
    String? text,
  }) async {
    images.add((png, name, text));
  }

  @override
  Future<void> shareText(String text, {String? subject}) async {
    texts.add((text, subject));
  }
}
