/// Numbers with their units, as the settings show them. Units are the same in
/// every language, so these are not in the ARB files.
abstract final class Formats {
  static String pixels(double value) => '${value.toStringAsFixed(1)} PX';
  static String times(double value) => 'x${value.toStringAsFixed(2)}';
  static String percent(double fraction) => '${(fraction * 100).round()}%';
  static String logicalPixels(double value) => '${value.round()} PX';
}
