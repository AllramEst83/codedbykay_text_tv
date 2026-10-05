import 'package:codedbykay_text_tv/messages.dart';
import 'package:codedbykay_text_tv/model/network_failure.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('NetworkFailure', () {
    test('what may pass is worth another try, what will not is not', () {
      expect(NetworkFailure.offline.transient, isTrue);
      expect(NetworkFailure.timeout.transient, isTrue);
      expect(NetworkFailure.server.transient, isTrue);
      expect(NetworkFailure.changed.transient, isFalse);
      expect(NetworkFailure.other.transient, isFalse);
    });

    test('every kind has its own wording', () {
      final Set<String> words = <String>{
        for (final NetworkFailure f in NetworkFailure.values)
          Messages.failure(f),
      };

      expect(words, hasLength(NetworkFailure.values.length));
    });
  });
}
