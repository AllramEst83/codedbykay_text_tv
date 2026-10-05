import 'package:codedbykay_text_tv/model/background_settings.dart';
import 'package:codedbykay_text_tv/services/background_refresher.dart';
import 'package:codedbykay_text_tv/services/background_scheduler.dart';
import 'package:codedbykay_text_tv/services/widget_platform.dart';

DateTime _systemNow() => DateTime.now();

/// Decides whether the background job should be running, and starts and stops
/// it: it runs only while there is something for it to do (a widget on a home
/// screen), so an app with no widget costs nothing in the background.
class BackgroundCoordinator {
  BackgroundCoordinator({
    required this.scheduler,
    required this.widget,
    required this.refresher,
    this.clock = _systemNow,
    this.freshFor = const Duration(minutes: 5),
  });

  final BackgroundScheduler scheduler;
  final WidgetPlatform widget;
  final BackgroundRefresher refresher;
  final DateTime Function() clock;

  /// A refresh from the app is skipped if one ran this recently.
  final Duration freshFor;

  DateTime? _lastRun;

  /// Starts or stops the job to suit [settings] and the widgets there are.
  Future<void> apply(BackgroundSettings settings) async {
    if (await widget.hasWidgets()) {
      await scheduler.schedule(settings.every);
    } else {
      await scheduler.cancel();
    }
  }

  /// The app has come to the front: bring the widget up to date at once (a
  /// widget just added has nothing yet), unless that was done a moment ago.
  /// Also sets the job going or stops it, for a widget added or removed
  /// since.
  Future<void> appResumed(BackgroundSettings settings) async {
    await apply(settings);
    final DateTime now = clock();
    final DateTime? last = _lastRun;
    if (last != null && now.difference(last) < freshFor) return;
    _lastRun = now;
    await refresher.run();
  }
}
