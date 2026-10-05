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

/// How the app reads pages beyond the one asked for: whether the page on
/// screen refreshes by itself, and whether pages likely to be asked for next
/// are read ahead. Read from disk, so decoding is tolerant: a bad value is
/// replaced by its default.
class RefreshSettings {
  const RefreshSettings({this.auto = 0, this.prefetch = true});

  /// An index into [autoRefreshIntervals].
  final int auto;

  /// Read the neighbouring and linked pages ahead, so paging is instant. A
  /// few extra requests for each page viewed (see `prefetchLimit`).
  final bool prefetch;

  /// How often to refresh, or null for never.
  Duration? get interval => autoRefreshIntervals[auto];

  RefreshSettings copyWith({int? auto, bool? prefetch}) => RefreshSettings(
    auto: auto ?? this.auto,
    prefetch: prefetch ?? this.prefetch,
  );

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
    final Object? prefetch = json['prefetch'];
    return RefreshSettings(
      auto: auto is int && auto >= 0 && auto < autoRefreshIntervals.length
          ? auto
          : 0,
      prefetch: prefetch is bool ? prefetch : true,
    );
  }

  String encode() =>
      jsonEncode(<String, Object?>{'auto': auto, 'prefetch': prefetch});

  @override
  bool operator ==(Object other) =>
      other is RefreshSettings &&
      other.auto == auto &&
      other.prefetch == prefetch;

  @override
  int get hashCode => Object.hash(auto, prefetch);
}
