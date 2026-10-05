import 'dart:convert';

/// How far the glass may bulge: 0 is flat. Past this the page's edges are
/// squeezed too hard to read and taps land too far from what is shown.
const double crtCurveMax = 0.06;

/// How dark the scanline gaps may get (0 is none, 1 would be black).
const double crtScanDepthMax = 0.35;

/// How many logical pixels one scanline takes: closer than the minimum
/// shimmers, further than the maximum looks like stripes.
const double crtScanPeriodMin = 2;
const double crtScanPeriodMax = 5;

const double _defaultCurve = 0.03;
const double _defaultScanDepth = 0.18;
const double _defaultScanPeriod = 3;

/// The CRT look of the teletext page: on or off and the three things that make
/// it. Every value is kept inside the range above, whoever sets it, so no
/// setting can make the page unreadable. Read from disk, so decoding is
/// tolerant: a bad field is replaced by its default.
class CrtSettings {
  /// Values outside the ranges are brought to the nearest end.
  factory CrtSettings({
    bool enabled = false,
    double curve = _defaultCurve,
    double scanDepth = _defaultScanDepth,
    double scanPeriod = _defaultScanPeriod,
  }) => CrtSettings._(
    enabled,
    _within(curve, 0, crtCurveMax, _defaultCurve),
    _within(scanDepth, 0, crtScanDepthMax, _defaultScanDepth),
    _within(scanPeriod, crtScanPeriodMin, crtScanPeriodMax, _defaultScanPeriod),
  );

  const CrtSettings._(
    this.enabled,
    this.curve,
    this.scanDepth,
    this.scanPeriod,
  );

  /// The look a fresh install has, switched off.
  static const CrtSettings defaults = CrtSettings._(
    false,
    _defaultCurve,
    _defaultScanDepth,
    _defaultScanPeriod,
  );

  final bool enabled;

  /// How far the glass bulges, 0 to [crtCurveMax].
  final double curve;

  /// How dark the gaps between scanlines are, 0 to [crtScanDepthMax].
  final double scanDepth;

  /// Logical pixels per scanline, [crtScanPeriodMin] to [crtScanPeriodMax].
  final double scanPeriod;

  CrtSettings copyWith({
    bool? enabled,
    double? curve,
    double? scanDepth,
    double? scanPeriod,
  }) => CrtSettings(
    enabled: enabled ?? this.enabled,
    curve: curve ?? this.curve,
    scanDepth: scanDepth ?? this.scanDepth,
    scanPeriod: scanPeriod ?? this.scanPeriod,
  );

  /// The three looks put back to their defaults, the switch left as it is.
  CrtSettings reset() => CrtSettings(enabled: enabled);

  static double _within(double value, double min, double max, double fallback) {
    if (value.isNaN || value.isInfinite) return fallback;
    return value.clamp(min, max);
  }

  static double _number(Object? value, double fallback) =>
      value is num ? value.toDouble() : fallback;

  factory CrtSettings.decode(String? source) {
    if (source == null) return defaults;
    final Object? json;
    try {
      json = jsonDecode(source);
    } on FormatException {
      return defaults;
    }
    if (json is! Map<String, Object?>) return defaults;
    final Object? enabled = json['enabled'];
    return CrtSettings(
      enabled: enabled is bool && enabled,
      curve: _number(json['curve'], _defaultCurve),
      scanDepth: _number(json['scanDepth'], _defaultScanDepth),
      scanPeriod: _number(json['scanPeriod'], _defaultScanPeriod),
    );
  }

  String encode() => jsonEncode(<String, Object?>{
    'enabled': enabled,
    'curve': curve,
    'scanDepth': scanDepth,
    'scanPeriod': scanPeriod,
  });

  @override
  bool operator ==(Object other) =>
      other is CrtSettings &&
      other.enabled == enabled &&
      other.curve == curve &&
      other.scanDepth == scanDepth &&
      other.scanPeriod == scanPeriod;

  @override
  int get hashCode => Object.hash(enabled, curve, scanDepth, scanPeriod);
}
