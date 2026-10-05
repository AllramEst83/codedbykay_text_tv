import 'package:codedbykay_text_tv/model/text_tv_headlines.dart';
import 'package:codedbykay_text_tv/model/text_tv_page.dart';

/// What the home-screen widget shows: a page's number, its headlines and when
/// they were read.
class WidgetContent {
  const WidgetContent({
    required this.page,
    required this.lines,
    required this.updated,
  });

  /// As many headlines as the widget has room for.
  static const int maxLines = 8;

  /// Longest a headline is kept; a widget line is short.
  static const int maxLineLength = 60;

  final int page;
  final List<String> lines;

  /// When the page was read, as `14:32`.
  final String updated;

  /// The widget's content for [page] read at [now].
  factory WidgetContent.of(TextTvPage page, DateTime now) {
    String two(int n) => n.toString().padLeft(2, '0');
    return WidgetContent(
      page: page.number,
      lines: <String>[
        for (final String line in textTvHeadlines(page).take(maxLines))
          line.length > maxLineLength ? line.substring(0, maxLineLength) : line,
      ],
      updated: '${two(now.hour)}:${two(now.minute)}',
    );
  }

  @override
  bool operator ==(Object other) =>
      other is WidgetContent &&
      other.page == page &&
      other.updated == updated &&
      other.lines.length == lines.length &&
      Iterable<int>.generate(lines.length)
          .every((int i) => other.lines[i] == lines[i]);

  @override
  int get hashCode => Object.hash(page, updated, Object.hashAll(lines));
}
