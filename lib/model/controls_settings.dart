import 'dart:convert';

/// How the controls under the page work. Read from disk, so decoding is
/// tolerant: a bad value means the default.
class ControlsSettings {
  const ControlsSettings({this.quickEntry = false, this.breadcrumbs = true});

  /// Off: the way the app first worked. The page number box opens a number pad
  /// (with DEL and a key that puts it away) in place of the shortcuts, and
  /// the page gets the most height.
  ///
  /// On: a compact number pad is always on screen, and a page with links in
  /// its bottom row gets red, green, yellow and blue keys for them; the page
  /// has less height.
  final bool quickEntry;

  /// A row above the page with the way down to it (`HOME > SPORT > 330 >
  /// 377`), each step a tap back up. On to start with; it costs the page a
  /// line of height, so it can be switched off.
  final bool breadcrumbs;

  static const ControlsSettings defaults = ControlsSettings();

  ControlsSettings copyWith({bool? quickEntry, bool? breadcrumbs}) =>
      ControlsSettings(
        quickEntry: quickEntry ?? this.quickEntry,
        breadcrumbs: breadcrumbs ?? this.breadcrumbs,
      );

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
    final Object? crumbs = json['breadcrumbs'];
    return ControlsSettings(
      quickEntry: quick is bool && quick,
      // Not saved by an older version: on, as it starts.
      breadcrumbs: crumbs is bool ? crumbs : true,
    );
  }

  String encode() => jsonEncode(<String, Object?>{
    'quickEntry': quickEntry,
    'breadcrumbs': breadcrumbs,
  });

  @override
  bool operator ==(Object other) =>
      other is ControlsSettings &&
      other.quickEntry == quickEntry &&
      other.breadcrumbs == breadcrumbs;

  @override
  int get hashCode => Object.hash(quickEntry, breadcrumbs);
}
