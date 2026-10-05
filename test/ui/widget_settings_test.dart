import 'package:codedbykay_text_tv/model/background_settings.dart';
import 'package:codedbykay_text_tv/model/saved_pages.dart';
import 'package:codedbykay_text_tv/model/text_tv_page.dart';
import 'package:codedbykay_text_tv/services/open_page_service.dart';
import 'package:codedbykay_text_tv/ui/text_tv_keys.dart';
import 'package:codedbykay_text_tv/ui/text_tv_screen.dart';
import 'package:codedbykay_text_tv/ui/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fakes/english.dart';
import '../fakes/fake_text_tv_repository.dart';

FakeTextTvRepository _repository() => FakeTextTvRepository(<int, TextTvPage>{
  for (int n = 100; n <= 799; n++)
    n: TextTvPage(
      number: n,
      parts: <List<String>>[
        <String>['$n SVT Text', 'Sida $n'],
      ],
    ),
});

class _Opened {
  final List<BackgroundSettings> changes = <BackgroundSettings>[];
  int resumed = 0;
}

Future<_Opened> _open(
  WidgetTester tester, {
  BackgroundSettings background = BackgroundSettings.defaults,
  OpenPageService? openPages,
  SavedPages saved = const SavedPages(),
}) async {
  tester.view
    ..physicalSize = const Size(800, 3000)
    ..devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final _Opened opened = _Opened();
  await tester.pumpWidget(
    MaterialApp(
      theme: textTvTheme(),
      home: TextTvScreen(
        repository: _repository(),
        background: background,
        onBackgroundChanged: opened.changes.add,
        openPages: openPages,
        onResumed: () => opened.resumed++,
        saved: saved,
      ),
    ),
  );
  await tester.pumpAndSettle();
  return opened;
}

Future<void> _openSettings(WidgetTester tester) async {
  await tester.tap(find.byKey(textTvSettingsKey));
  await tester.pumpAndSettle();
}

Finder _number(String text) =>
    find.descendant(of: find.byKey(textTvNumberKey), matching: find.text(text));

void main() {
  group('the widget group in settings', () {
    testWidgets('shows the page, the interval and a note', (
      WidgetTester tester,
    ) async {
      await _open(tester);
      await _openSettings(tester);
      await tester.scrollUntilVisible(find.byKey(textTvBackgroundNoteKey), 200);

      expect(find.byKey(textTvSettingsGroupKey('background')), findsOneWidget);
      expect(find.text(en.sectionBackground), findsOneWidget);
      expect(
        find.descendant(
          of: find.byKey(textTvWidgetPageKey),
          matching: find.text('100 NEWS'),
        ),
        findsOneWidget,
      );
      for (int i = 0; i < backgroundIntervals.length; i++) {
        expect(find.byKey(textTvIntervalKey(i)), findsOneWidget);
      }
      expect(find.text('1 H'), findsOneWidget);
      expect(find.text(en.backgroundNote), findsOneWidget);
    });

    testWidgets('choosing an interval reports it', (WidgetTester tester) async {
      final _Opened opened = await _open(tester);
      await _openSettings(tester);
      await tester.scrollUntilVisible(find.byKey(textTvIntervalKey(2)), 200);

      await tester.tap(find.byKey(textTvIntervalKey(2)));
      await tester.pumpAndSettle();

      expect(opened.changes.last.interval, 2);
    });

    testWidgets('choosing what is chosen reports nothing', (
      WidgetTester tester,
    ) async {
      final _Opened opened = await _open(tester);
      await _openSettings(tester);
      await tester.scrollUntilVisible(find.byKey(textTvIntervalKey(1)), 200);

      await tester.tap(find.byKey(textTvIntervalKey(1)));
      await tester.pumpAndSettle();

      expect(opened.changes, isEmpty);
    });

    testWidgets('the widget page is picked from a list of favourites', (
      WidgetTester tester,
    ) async {
      final _Opened opened = await _open(tester);
      await _openSettings(tester);
      await tester.scrollUntilVisible(find.byKey(textTvWidgetPageKey), 200);

      await tester.tap(find.byKey(textTvWidgetPageKey));
      await tester.pumpAndSettle();
      expect(find.text(en.pickerTitle), findsOneWidget);
      // The chosen one first, the other favourites after it.
      expect(find.byKey(textTvPickKey(100)), findsOneWidget);
      expect(find.byKey(textTvPickKey(300)), findsOneWidget);

      await tester.tap(find.byKey(textTvPickKey(300)));
      await tester.pumpAndSettle();

      expect(opened.changes.last.widgetPage, 300);
      expect(
        find.descendant(
          of: find.byKey(textTvWidgetPageKey),
          matching: find.text('300 SPORT'),
        ),
        findsOneWidget,
      );
    });

    testWidgets('a page that is not a favourite is still offered if chosen', (
      WidgetTester tester,
    ) async {
      await _open(
        tester,
        background: const BackgroundSettings(widgetPage: 555),
      );
      await _openSettings(tester);
      await tester.scrollUntilVisible(find.byKey(textTvWidgetPageKey), 200);

      await tester.tap(find.byKey(textTvWidgetPageKey));
      await tester.pumpAndSettle();

      expect(find.byKey(textTvPickKey(555)), findsOneWidget);
    });
  });

  group('a tap on the widget', () {
    testWidgets('opens the page it was set to', (WidgetTester tester) async {
      final OpenPageService service = OpenPageService();
      addTearDown(service.dispose);
      await _open(tester, openPages: service);

      service.request(377);
      await tester.pumpAndSettle();

      expect(_number('377'), findsOneWidget);
    });

    testWidgets('that started the app is opened as soon as the screen is up', (
      WidgetTester tester,
    ) async {
      final OpenPageService service = OpenPageService()..request(450);
      addTearDown(service.dispose);

      await _open(tester, openPages: service);

      expect(_number('450'), findsOneWidget);
    });
  });
}
