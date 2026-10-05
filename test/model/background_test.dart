import 'package:codedbykay_text_tv/model/background_settings.dart';
import 'package:codedbykay_text_tv/model/launch_link.dart';
import 'package:codedbykay_text_tv/model/text_tv_page.dart';
import 'package:codedbykay_text_tv/model/widget_content.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('BackgroundSettings', () {
    test('start on page 100, checking every hour', () {
      const BackgroundSettings s = BackgroundSettings();

      expect(s.widgetPage, 100);
      expect(s.every, const Duration(hours: 1));
    });

    test('every wait is above the system floor of 15 minutes', () {
      for (final Duration d in backgroundIntervals) {
        expect(d, greaterThan(const Duration(minutes: 15)));
      }
    });

    test('survive a round trip', () {
      const BackgroundSettings s = BackgroundSettings(
        widgetPage: 377,
        interval: 2,
      );

      expect(BackgroundSettings.decode(s.encode()), s);
      expect(
        BackgroundSettings.decode(s.encode()).every,
        backgroundIntervals[2],
      );
    });

    test('nothing saved, nonsense or a bad field gives the defaults', () {
      for (final String? source in <String?>[null, '', 'garbage', '[]', '{}']) {
        expect(
          BackgroundSettings.decode(source),
          BackgroundSettings.defaults,
          reason: '$source',
        );
      }
      final BackgroundSettings bad = BackgroundSettings.decode(
        '{"widgetPage": 42, "interval": 9}',
      );
      expect(bad.widgetPage, 100);
      expect(bad.interval, backgroundDefaultInterval);
      expect(BackgroundSettings.decode('{"widgetPage": "x"}').widgetPage, 100);
    });

    test('copyWith changes only what it is told to', () {
      const BackgroundSettings s = BackgroundSettings(
        widgetPage: 300,
        interval: 0,
      );

      expect(
        s.copyWith(interval: 2),
        const BackgroundSettings(widgetPage: 300, interval: 2),
      );
      expect(s.copyWith(widgetPage: 400).interval, 0);
      expect(
        s.hashCode,
        const BackgroundSettings(widgetPage: 300, interval: 0).hashCode,
      );
    });
  });

  group('WidgetContent', () {
    final TextTvPage page = TextTvPage(
      number: 100,
      parts: <List<String>>[
        <String>[
          '100 SVT Text lördag 26 sep',
          'Första rubriken 105',
          '',
          '105',
          'Andra rubriken',
          for (int i = 0; i < 10; i++) 'Rubrik $i',
          'En ${'mycket ' * 20}lång rubrik',
        ],
      ],
    );

    test('are the headlines, with no title row and no page numbers', () {
      final WidgetContent c = WidgetContent.of(
        page,
        DateTime(2026, 10, 5, 9, 7),
      );

      expect(c.page, 100);
      expect(c.lines.first, 'Första rubriken');
      expect(c.lines[1], 'Andra rubriken');
      expect(c.lines, isNot(contains('105')));
    });

    test('are no more than the widget has room for', () {
      final WidgetContent c = WidgetContent.of(page, DateTime(2026, 10, 5));

      expect(c.lines, hasLength(WidgetContent.maxLines));
    });

    test('keep a long headline short', () {
      final WidgetContent c = WidgetContent.of(
        TextTvPage(
          number: 100,
          parts: <List<String>>[
            <String>['100', 'x' * 200],
          ],
        ),
        DateTime(2026, 10, 5),
      );

      expect(c.lines.single.length, WidgetContent.maxLineLength);
    });

    test('say when they were read, with two digits', () {
      expect(
        WidgetContent.of(page, DateTime(2026, 10, 5, 9, 7)).updated,
        '09:07',
      );
    });

    test('are equal when all of it is', () {
      final DateTime t = DateTime(2026, 10, 5, 9, 7);

      expect(WidgetContent.of(page, t), WidgetContent.of(page, t));
      expect(
        WidgetContent.of(page, t).hashCode,
        WidgetContent.of(page, t).hashCode,
      );
      expect(
        WidgetContent.of(page, t),
        isNot(WidgetContent.of(page, t.add(const Duration(minutes: 1)))),
      );
    });
  });

  group('launch links', () {
    test('a link for a page reads back as that page', () {
      for (final int page in <int>[100, 377, 899]) {
        expect(pageOfLaunchLink(launchLinkFor(page)), page);
      }
      expect(launchLinkFor(377).toString(), 'texttv://page/377');
    });

    test('anything that is not one of ours is not a page', () {
      for (final String? link in <String?>[
        null,
        'texttv://page/99',
        'texttv://page/900',
        'texttv://page/abc',
        'texttv://page/',
        'texttv://page/100/200',
        'texttv://other/100',
        'https://texttv.nu/100',
        'page/100',
      ]) {
        expect(
          pageOfLaunchLink(link == null ? null : Uri.parse(link)),
          isNull,
          reason: '$link',
        );
      }
    });
  });
}
