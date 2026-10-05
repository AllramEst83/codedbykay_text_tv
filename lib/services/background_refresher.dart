import 'package:codedbykay_text_tv/model/background_settings.dart';
import 'package:codedbykay_text_tv/model/headline_watch.dart';
import 'package:codedbykay_text_tv/model/text_tv_page.dart';
import 'package:codedbykay_text_tv/model/widget_content.dart';
import 'package:codedbykay_text_tv/services/alert_platform.dart';
import 'package:codedbykay_text_tv/services/background_settings_store.dart';
import 'package:codedbykay_text_tv/services/network_exception.dart';
import 'package:codedbykay_text_tv/services/text_tv.dart';
import 'package:codedbykay_text_tv/services/widget_platform.dart';

DateTime _systemNow() => DateTime.now();

/// The work of one background run: read the widget's page and give it to the
/// widget; and, when alerts are on, read the watched page and say if its top
/// headline is new. It runs from the periodic job (in its own isolate) and from
/// the app when it comes to the front, so it holds no state of its own and
/// never throws: a run that fails is a run that did nothing, and the widget
/// keeps what it showed.
///
/// Asks for at most two pages, one second apart (one, when widget and alerts
/// are on the same page).
class BackgroundRefresher {
  BackgroundRefresher({
    required this.textTv,
    required this.settings,
    required this.widget,
    this.alerts,
    this.watch,
    this.memory,
    this.clock = _systemNow,
    this.pause = const Duration(seconds: 1),
  });

  final TextTv textTv;
  final BackgroundSettingsStore settings;
  final WidgetPlatform widget;

  /// Where an alert is shown, and the memory of what the alerts last saw;
  /// without them there are no alerts.
  final AlertPlatform? alerts;
  final WatchStateStore? watch;

  /// What was last seen of each page, so a run can ask the site whether a page
  /// changed (a few hundred bytes) before reading it. Without it every run
  /// reads every page.
  final BackgroundMemoryStore? memory;
  final DateTime Function() clock;

  /// Between the two pages of a run.
  final Duration pause;

  /// One run. With [alert] false (the reader has the app open and is looking
  /// at the news) what the alerts see is remembered but not announced.
  Future<void> run({bool alert = true}) async {
    try {
      final BackgroundSettings current = await settings.load();
      final bool widgetNeeded = await widget.hasWidgets();
      final bool alertsNeeded =
          current.alerts && alerts != null && watch != null;
      int? widgetNumber;
      TextTvPage? widgetPage;

      if (widgetNeeded) {
        widgetNumber = current.widgetPage;
        // A widget that has not been given this page yet needs it whatever the
        // site says (it was just added, or its page was changed).
        final bool needed = (await memory?.load())?.widgetShown != widgetNumber;
        widgetPage = await _read(widgetNumber, force: needed);
        if (widgetPage != null) {
          await widget.publish(WidgetContent.of(widgetPage, clock()));
          final BackgroundMemoryStore? store = memory;
          if (store != null) {
            await store.save(
              (await store.load()).withWidgetShown(widgetNumber),
            );
          }
        }
      }
      if (alertsNeeded) {
        final int number = current.alertPage;
        TextTvPage? page;
        if (widgetNumber == number) {
          // Already asked for this page a moment ago: use that answer, or if
          // there was none, wait for the next run.
          page = widgetPage;
        } else {
          if (widgetNumber != null) await Future<void>.delayed(pause);
          // Alerts that have seen nothing of this page yet need it too: the
          // first look is what later ones are compared with.
          final bool unseen = (await watch!.load()).forPage(number).isEmpty;
          page = await _read(number, force: unseen);
        }
        if (page != null) await _watch(page, announce: alert);
      }
    } on Object {
      // Nothing to do about it here: the next run tries again.
    }
  }

  /// The page, or null when it did not change since the last read (asked of the
  /// site first, unless [force]) or could not be read. A page read is
  /// remembered with the time the site gave for it.
  Future<TextTvPage?> _read(int number, {bool force = false}) async {
    final BackgroundMemoryStore? store = memory;
    try {
      if (store != null && !force) {
        final int? since = (await store.load()).updated[number];
        if (since != null) {
          if (!await textTv.hasUpdate(number, since)) return null;
          // Two requests to one site in a row: a breath between them.
          await Future<void>.delayed(pause ~/ 4);
        }
      }
      final TextTvPage? page = await textTv.page(number);
      if (page != null && store != null) {
        final int stamp =
            page.updatedUnix ?? clock().millisecondsSinceEpoch ~/ 1000;
        await store.save((await store.load()).withUpdated(number, stamp));
      }
      return page;
    } on NetworkException {
      return null;
    }
  }

  Future<void> _watch(TextTvPage page, {required bool announce}) async {
    final WatchStateStore store = watch!;
    final List<String> seen = (await store.load()).forPage(page.number);
    final List<String> now = watchedHeadlines(page);
    // Remembered before it is announced: a notification that fails is not
    // worth announcing the same headline again and again.
    await store.save(WatchState(page: page.number, headlines: now));
    final String? news = breakingHeadline(seen, now);
    if (news != null && announce) await alerts!.show(page.number, news);
  }
}
