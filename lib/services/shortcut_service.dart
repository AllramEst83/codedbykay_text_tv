import 'dart:async';

import 'package:codedbykay_text_tv/model/saved_pages.dart';
import 'package:codedbykay_text_tv/model/shortcuts.dart';
import 'package:quick_actions/quick_actions.dart';

/// The platform side of the app icon's shortcuts, as little as it can be: give
/// it entries, hear which one was chosen. [QuickActionsShortcuts] is the real
/// one; tests use a fake.
abstract interface class ShortcutPlatform {
  /// Starts listening: [onChosen] gets the `type` of the shortcut that opened
  /// the app or was chosen while it ran.
  Future<void> start(void Function(String type) onChosen);

  /// Makes [entries] the shortcuts, replacing the ones there were.
  Future<void> set(List<ShortcutEntry> entries);
}

/// [ShortcutPlatform] on the `quick_actions` plugin (Android app shortcuts).
class QuickActionsShortcuts implements ShortcutPlatform {
  QuickActionsShortcuts({this.icon = 'ic_launcher'});

  /// The name of an icon in the app's resources (drawable or mipmap): the
  /// launcher icon, so a shortcut looks like the app.
  final String icon;

  final QuickActions _actions = const QuickActions();

  @override
  Future<void> start(void Function(String type) onChosen) =>
      _actions.initialize(onChosen);

  @override
  Future<void> set(List<ShortcutEntry> entries) =>
      _actions.setShortcutItems(<ShortcutItem>[
        for (final ShortcutEntry e in entries)
          ShortcutItem(type: e.type, localizedTitle: e.title, icon: icon),
      ]);
}

/// Keeps the app icon's long-press menu in step with the favourites, and says
/// which page was chosen from it. Nothing here throws: a phone that cannot do
/// shortcuts just has none.
class ShortcutService {
  ShortcutService(this._platform);

  final ShortcutPlatform _platform;

  // One listener (the viewer) and a buffer for what happens before it listens:
  // a shortcut that starts the app is heard before the screen is up.
  final StreamController<int> _opened = StreamController<int>();

  /// The pages chosen from the shortcuts, in order. Anything chosen before the
  /// first listener is kept for it.
  Stream<int> get opened => _opened.stream;

  /// Starts listening for a shortcut being chosen. Call once.
  Future<void> start() async {
    try {
      await _platform.start((String type) {
        final int? page = pageOfShortcut(type);
        if (page != null && !_opened.isClosed) _opened.add(page);
      });
    } on Object {
      // No shortcuts on this phone: the app is the same without them.
    }
  }

  /// Makes the first favourites the shortcuts (see [shortcutsFor]).
  Future<void> update(List<Favourite> favourites) async {
    try {
      await _platform.set(shortcutsFor(favourites));
    } on Object {
      // As in [start].
    }
  }

  /// Stops listening. Does not wait for the stream to finish: a single-listener
  /// stream only finishes once somebody has listened, and nobody may have.
  Future<void> dispose() async {
    if (!_opened.isClosed) unawaited(_opened.close());
  }
}
