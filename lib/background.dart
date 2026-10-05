import 'package:codedbykay_text_tv/services/background_refresher.dart';
import 'package:codedbykay_text_tv/services/background_settings_store.dart';
import 'package:codedbykay_text_tv/services/io_http_fetcher.dart';
import 'package:codedbykay_text_tv/services/text_tv.dart';
import 'package:codedbykay_text_tv/services/widget_platform.dart';
import 'package:workmanager/workmanager.dart';

/// Where the background job starts, in an isolate of its own with no screen:
/// it builds what it needs from scratch, does one [BackgroundRefresher.run] and
/// says it went well (a failed run is not worth the system's retry; the next
/// period is soon enough).
@pragma('vm:entry-point')
void backgroundDispatcher() {
  Workmanager().executeTask((String task, Map<String, dynamic>? input) async {
    await BackgroundRefresher(
      textTv: TextTv(fetcher: IoHttpFetcher()),
      settings: PrefsBackgroundSettingsStore(),
      widget: const HomeWidgetPlatform(),
    ).run();
    return true;
  });
}
