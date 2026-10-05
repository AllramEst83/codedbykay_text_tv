import 'package:codedbykay_text_tv/model/shortcuts.dart';
import 'package:codedbykay_text_tv/services/shortcut_service.dart';

/// A phone's shortcut menu, in memory: records what it is given and lets a test
/// choose one, as pressing the app icon would.
class FakeShortcutPlatform implements ShortcutPlatform {
  /// Every list the shortcuts were set to, in order.
  final List<List<ShortcutEntry>> sets = <List<ShortcutEntry>>[];

  void Function(String type)? _onChosen;
  int starts = 0;

  /// Make [start] or [set] fail, like a phone that cannot do shortcuts.
  bool failing = false;

  List<ShortcutEntry> get current =>
      sets.isEmpty ? const <ShortcutEntry>[] : sets.last;

  @override
  Future<void> start(void Function(String type) onChosen) async {
    starts++;
    if (failing) throw StateError('no shortcuts here');
    _onChosen = onChosen;
  }

  @override
  Future<void> set(List<ShortcutEntry> entries) async {
    if (failing) throw StateError('no shortcuts here');
    sets.add(entries);
  }

  /// The reader chooses a shortcut of [type] from the app icon.
  void choose(String type) => _onChosen?.call(type);
}
