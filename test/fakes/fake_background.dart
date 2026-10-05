import 'package:codedbykay_text_tv/model/background_settings.dart';
import 'package:codedbykay_text_tv/model/headline_watch.dart';
import 'package:codedbykay_text_tv/model/widget_content.dart';
import 'package:codedbykay_text_tv/services/alert_platform.dart';
import 'package:codedbykay_text_tv/services/background_scheduler.dart';
import 'package:codedbykay_text_tv/services/background_settings_store.dart';
import 'package:codedbykay_text_tv/services/widget_platform.dart';

/// The home-screen widget, in memory: records what it was given and lets a
/// test say whether the user has put it on a home screen and tap it.
class FakeWidgetPlatform implements WidgetPlatform {
  /// Everything published, in order.
  final List<WidgetContent> published = <WidgetContent>[];

  bool installed = true;
  void Function(int page)? _onPage;

  @override
  Future<void> start(void Function(int page) onPage) async {
    _onPage = onPage;
  }

  @override
  Future<void> publish(WidgetContent content) async {
    published.add(content);
  }

  @override
  Future<bool> hasWidgets() async => installed;

  /// The user taps the widget, which is set to open [page].
  void tap(int page) => _onPage?.call(page);
}

/// The phone's background scheduler, in memory.
class FakeBackgroundScheduler implements BackgroundScheduler {
  /// Every period asked for, in order.
  final List<Duration> scheduled = <Duration>[];
  int cancels = 0;

  bool get running => scheduled.isNotEmpty && cancels < _total;
  int get _total => scheduled.length + cancels;

  /// What the job is doing now: its period, or null when stopped.
  Duration? current;

  @override
  Future<void> schedule(Duration every) async {
    scheduled.add(every);
    current = every;
  }

  @override
  Future<void> cancel() async {
    cancels++;
    current = null;
  }
}

/// The background settings, in memory.
class FakeBackgroundSettingsStore implements BackgroundSettingsStore {
  FakeBackgroundSettingsStore([this.settings = BackgroundSettings.defaults]);

  BackgroundSettings settings;

  @override
  Future<BackgroundSettings> load() async => settings;

  @override
  Future<void> save(BackgroundSettings s) async => settings = s;
}

/// The phone's notifications, in memory: records what was shown and lets a test
/// say whether the user allows them.
class FakeAlertPlatform implements AlertPlatform {
  /// Every `(page, headline)` shown, in order.
  final List<(int, String)> shown = <(int, String)>[];

  /// What the user answers when asked for permission.
  bool permission = true;
  int asked = 0;
  void Function(int page)? _onPage;

  @override
  Future<void> start(void Function(int page) onPage) async {
    _onPage = onPage;
  }

  @override
  Future<bool> requestPermission() async {
    asked++;
    return permission;
  }

  @override
  Future<bool> allowed() async => permission;

  @override
  Future<void> show(int page, String headline) async {
    shown.add((page, headline));
  }

  /// The user taps a notification for [page].
  void tap(int page) => _onPage?.call(page);
}

/// What the alerts last saw, in memory.
class FakeWatchStateStore implements WatchStateStore {
  WatchState state = const WatchState();

  @override
  Future<WatchState> load() async => state;

  @override
  Future<void> save(WatchState s) async => state = s;
}
