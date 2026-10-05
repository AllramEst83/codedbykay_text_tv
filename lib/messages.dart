/// Every string the viewer shows, so the wording stays in one place.
abstract final class Messages {
  static const String title = 'TEXT TV';
  static const String loading = 'LOADING...';
  static const String tryAgain = 'TRY AGAIN';
  static const String refresh = 'REFRESH';
  static const String part = 'PART';
  static String offlineSaved(String when) => 'OFFLINE. SAVED $when';
  static String pageNotBroadcast(int number) =>
      'PAGE $number IS NOT IN BROADCAST.';
}
