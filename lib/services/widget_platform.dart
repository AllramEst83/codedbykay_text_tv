import 'package:codedbykay_text_tv/model/launch_link.dart';
import 'package:codedbykay_text_tv/model/widget_content.dart';
import 'package:home_widget/home_widget.dart';

/// The home-screen widget as the app sees it, as little as it can be:
/// [HomeWidgetPlatform] is the real one; tests use a fake. Nothing here throws:
/// a phone that cannot show widgets just has none.
abstract interface class WidgetPlatform {
  /// Starts hearing taps on the widget: [onPage] gets the page it was set to
  /// open, also when the tap is what started the app.
  Future<void> start(void Function(int page) onPage);

  /// Gives the widget [content] and has it redrawn.
  Future<void> publish(WidgetContent content);

  /// Whether the user has put the widget on a home screen.
  Future<bool> hasWidgets();
}

/// [WidgetPlatform] on the `home_widget` plugin and the Kotlin provider
/// `TextTvWidgetProvider` (see `android/`), which reads what is saved here.
class HomeWidgetPlatform implements WidgetPlatform {
  const HomeWidgetPlatform();

  /// The provider's class, as the plugin wants it.
  static const String provider = 'com.codedbykay.texttv.TextTvWidgetProvider';

  /// Keys the provider reads; keep in step with `TextTvWidgetProvider.kt`.
  static const String pageKey = 'widget_page';
  static const String updatedKey = 'widget_updated';
  static String lineKey(int index) => 'widget_line_$index';

  @override
  Future<void> start(void Function(int page) onPage) async {
    try {
      HomeWidget.widgetClicked.listen((Uri? link) {
        final int? page = pageOfLaunchLink(link);
        if (page != null) onPage(page);
      });
      final int? first = pageOfLaunchLink(
        await HomeWidget.initiallyLaunchedFromHomeWidget(),
      );
      if (first != null) onPage(first);
    } on Object {
      // No widgets here: nothing to hear.
    }
  }

  @override
  Future<void> publish(WidgetContent content) async {
    try {
      await HomeWidget.saveWidgetData<int>(pageKey, content.page);
      await HomeWidget.saveWidgetData<String>(updatedKey, content.updated);
      for (int i = 0; i < WidgetContent.maxLines; i++) {
        await HomeWidget.saveWidgetData<String>(
          lineKey(i),
          i < content.lines.length ? content.lines[i] : '',
        );
      }
      await HomeWidget.updateWidget(qualifiedAndroidName: provider);
    } on Object {
      // The widget keeps what it showed.
    }
  }

  @override
  Future<bool> hasWidgets() async {
    try {
      return (await HomeWidget.getInstalledWidgets()).isNotEmpty;
    } on Object {
      return false;
    }
  }
}
