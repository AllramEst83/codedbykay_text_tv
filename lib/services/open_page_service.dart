import 'dart:async';

/// Pages that something outside the screen asks to be opened (a tap on the
/// home-screen widget, a notification), handed to the viewer. Like the
/// shortcuts' stream it keeps what comes before the viewer listens: a tap
/// that starts the app is heard before the screen is up.
class OpenPageService {
  final StreamController<int> _requests = StreamController<int>();

  /// The pages asked for, in order, for the one listener (the viewer).
  Stream<int> get requests => _requests.stream;

  void request(int page) {
    if (!_requests.isClosed) _requests.add(page);
  }

  /// Stops listening. Does not wait for the stream to finish: a single-listener
  /// stream only finishes once somebody has listened, and nobody may have.
  Future<void> dispose() async {
    if (!_requests.isClosed) unawaited(_requests.close());
  }
}
