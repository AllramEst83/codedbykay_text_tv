/// When a saved page was saved, as short as is clear: `14:32` for today,
/// `3/10 14:32` for another day.
String formatSavedAt(DateTime saved, DateTime now) {
  String two(int n) => n.toString().padLeft(2, '0');
  final String time = '${two(saved.hour)}:${two(saved.minute)}';
  final bool today =
      saved.year == now.year &&
      saved.month == now.month &&
      saved.day == now.day;
  return today ? time : '${saved.day}/${saved.month} $time';
}
