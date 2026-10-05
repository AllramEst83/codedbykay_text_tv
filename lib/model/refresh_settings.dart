import 'dart:convert';

/// How often the page on screen may refresh itself, by step; step 0 is never.
/// The shortest is 30 seconds: texttv.nu documents no limit, so this stays
/// courteous to a free service run by one person.
const List<Duration?> autoRefreshIntervals = <Duration?>[
  null,
  Duration(seconds: 30),
  Duration(seconds: 60),
  Duration(minutes: 2),
];

/// A page that has been on screen this long is read again, quietly, when the
/// app comes back to the front.
const Duration refreshAfterResume = Duration(minutes: 2);

/// Whether the page on screen refreshes by itself. Read from disk, so decoding
/// is tolerant: a bad value means never.
class RefreshSettings {
  const RefreshSettings({this.auto = 0});

  /// An index into [autoRefreshIntervals].
  final int auto;

  /// How often to refresh, or null for never.
  Duration? get interval => autoRefreshIntervals[auto];

  RefreshSettings copyWith({int? auto}) =>
      RefreshSettings(auto: auto ?? this.auto);

  factory RefreshSettings.decode(String? source) {
    if (source == null) return const RefreshSettings();
    final Object? json;
    try {
      json = jsonDecode(source);
    } on FormatException {
      return const RefreshSettings();
    }
    if (json is! Map<String, Object?>) return const RefreshSettings();
    final Object? auto = json['auto'];
    return RefreshSettings(
      auto: auto is int && auto >= 0 && auto < autoRefreshIntervals.length
          ? auto
          : 0,
    );
  }

  String encode() => jsonEncode(<String, Object?>{'auto': auto});

  @override
  bool operator ==(Object other) =>
      other is RefreshSettings && other.auto == auto;

  @override
  int get hashCode => auto.hashCode;
}
