import 'package:codedbykay_text_tv/services/share_service.dart';

/// The share sheet, in memory: records what it was asked to share.
class FakeSharePlatform implements SharePlatform {
  /// Every `(text, subject)` shared, in order.
  final List<(String, String?)> texts = <(String, String?)>[];

  @override
  Future<void> shareText(String text, {String? subject}) async {
    texts.add((text, subject));
  }
}
