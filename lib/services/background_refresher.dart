import 'package:codedbykay_text_tv/model/background_settings.dart';
import 'package:codedbykay_text_tv/model/text_tv_page.dart';
import 'package:codedbykay_text_tv/model/widget_content.dart';
import 'package:codedbykay_text_tv/services/background_settings_store.dart';
import 'package:codedbykay_text_tv/services/network_exception.dart';
import 'package:codedbykay_text_tv/services/text_tv.dart';
import 'package:codedbykay_text_tv/services/widget_platform.dart';

DateTime _systemNow() => DateTime.now();

/// The work of one background run: read the widget's page and give it to the
/// widget. It runs from the periodic job (in its own isolate) and from the app
/// when it comes to the front, so it holds no state of its own and never
/// throws: a run that fails is a run that did nothing, and the widget keeps
/// what it showed.
class BackgroundRefresher {
  BackgroundRefresher({
    required this.textTv,
    required this.settings,
    required this.widget,
    this.clock = _systemNow,
  });

  final TextTv textTv;
  final BackgroundSettingsStore settings;
  final WidgetPlatform widget;
  final DateTime Function() clock;

  Future<void> run() async {
    try {
      final BackgroundSettings current = await settings.load();
      if (await widget.hasWidgets()) {
        await _refreshWidget(current.widgetPage);
      }
    } on Object {
      // Nothing to do about it here: the next run tries again.
    }
  }

  Future<void> _refreshWidget(int number) async {
    final TextTvPage? page;
    try {
      page = await textTv.page(number);
    } on NetworkException {
      return;
    }
    if (page == null) return;
    await widget.publish(WidgetContent.of(page, clock()));
  }
}
