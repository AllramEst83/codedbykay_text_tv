import 'dart:convert';

/// How the controls under the page work. Read from disk, so decoding is
/// tolerant: a bad value means the default.
class ControlsSettings {
  const ControlsSettings({this.quickEntry = false});

  /// Off: the way the app first worked. The page number box opens a number pad
  /// (with DEL and a key that puts it away) in place of the shortcuts, and
  /// the page gets the most height.
  ///
  /// On: a compact number pad is always on screen, and a page with links in
  /// its bottom row gets red, green, yellow and blue keys for them; the page
  /// has less height.
  final bool quickEntry;

  static const ControlsSettings defaults = ControlsSettings();

  ControlsSettings copyWith({bool? quickEntry}) =>
      ControlsSettings(quickEntry: quickEntry ?? this.quickEntry);

  factory ControlsSettings.decode(String? source) {
    if (source == null) return defaults;
    final Object? json;
    try {
      json = jsonDecode(source);
    } on FormatException {
      return defaults;
    }
    if (json is! Map<String, Object?>) return defaults;
    final Object? quick = json['quickEntry'];
    return ControlsSettings(quickEntry: quick is bool && quick);
  }

  String encode() => jsonEncode(<String, Object?>{'quickEntry': quickEntry});

  @override
  bool operator ==(Object other) =>
      other is ControlsSettings && other.quickEntry == quickEntry;

  @override
  int get hashCode => quickEntry.hashCode;
}
