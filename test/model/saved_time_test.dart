import 'package:codedbykay_text_tv/model/saved_time.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final DateTime now = DateTime(2026, 10, 5, 18, 30);

  test('today is just the time, with the minutes padded', () {
    expect(formatSavedAt(DateTime(2026, 10, 5, 14, 32), now), '14:32');
    expect(formatSavedAt(DateTime(2026, 10, 5, 7, 5), now), '07:05');
  });

  test('another day adds day and month', () {
    expect(formatSavedAt(DateTime(2026, 10, 3, 14, 32), now), '3/10 14:32');
  });

  test('the same day and month a year ago is not today', () {
    expect(formatSavedAt(DateTime(2025, 10, 5, 14, 32), now), '5/10 14:32');
  });
}
