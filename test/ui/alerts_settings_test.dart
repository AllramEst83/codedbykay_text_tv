import 'package:codedbykay_text_tv/model/background_settings.dart';
import 'package:codedbykay_text_tv/model/text_tv_page.dart';
import 'package:codedbykay_text_tv/ui/text_tv_keys.dart';
import 'package:codedbykay_text_tv/ui/text_tv_screen.dart';
import 'package:codedbykay_text_tv/ui/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fakes/english.dart';
import '../fakes/fake_background.dart';
import '../fakes/fake_text_tv_repository.dart';

FakeTextTvRepository _repository() => FakeTextTvRepository(<int, TextTvPage>{
  100: const TextTvPage(
    number: 100,
    parts: <List<String>>[
      <String>['100 SVT Text', 'Hej'],
    ],
  ),
});

Future<List<BackgroundSettings>> _open(
  WidgetTester tester, {
  BackgroundSettings background = BackgroundSettings.defaults,
  FakeAlertPlatform? alerts,
}) async {
  tester.view
    ..physicalSize = const Size(800, 3000)
    ..devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final List<BackgroundSettings> heard = <BackgroundSettings>[];
  await tester.pumpWidget(
    MaterialApp(
      theme: textTvTheme(),
      home: TextTvScreen(
        repository: _repository(),
        background: background,
        onBackgroundChanged: heard.add,
        alerts: alerts,
      ),
    ),
  );
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(textTvSettingsKey));
  await tester.pumpAndSettle();
  await tester.scrollUntilVisible(find.byKey(textTvAlertsKey), 200);
  return heard;
}

void main() {
  group('the alerts rows in settings', () {
    testWidgets('start off, with the page button greyed and a note', (
      WidgetTester tester,
    ) async {
      await _open(tester);

      expect(tester.widget<Switch>(find.byKey(textTvAlertsKey)).value, isFalse);
      expect(
        tester
            .widget<InkWell>(
              find.descendant(
                of: find.byKey(textTvAlertPageKey),
                matching: find.byType(InkWell),
              ),
            )
            .onTap,
        isNull,
      );
      await tester.scrollUntilVisible(find.byKey(textTvAlertsNoteKey), 200);
      expect(find.text(en.alertsNote), findsOneWidget);
    });

    testWidgets('turning them on asks the phone for permission first', (
      WidgetTester tester,
    ) async {
      final FakeAlertPlatform alerts = FakeAlertPlatform();
      final List<BackgroundSettings> heard = await _open(
        tester,
        alerts: alerts,
      );

      await tester.tap(find.byKey(textTvAlertsKey));
      await tester.pumpAndSettle();

      expect(alerts.asked, 1);
      expect(heard.last.alerts, isTrue);
      expect(tester.widget<Switch>(find.byKey(textTvAlertsKey)).value, isTrue);
    });

    testWidgets('a refusal leaves them off and says why', (
      WidgetTester tester,
    ) async {
      final FakeAlertPlatform alerts = FakeAlertPlatform()..permission = false;
      final List<BackgroundSettings> heard = await _open(
        tester,
        alerts: alerts,
      );

      await tester.tap(find.byKey(textTvAlertsKey));
      await tester.pumpAndSettle();

      expect(heard, isEmpty);
      expect(tester.widget<Switch>(find.byKey(textTvAlertsKey)).value, isFalse);
      expect(find.text(en.alertsDenied), findsOneWidget);
    });

    testWidgets('and the message has a button that opens the phone settings', (
      WidgetTester tester,
    ) async {
      final FakeAlertPlatform alerts = FakeAlertPlatform()..permission = false;
      await _open(tester, alerts: alerts);
      await tester.tap(find.byKey(textTvAlertsKey));
      await tester.pumpAndSettle();
      expect(alerts.settingsOpened, 0);

      expect(find.text(en.alertsOpenSettings), findsOneWidget);
      await tester.tap(find.byKey(textTvOpenSettingsKey));
      await tester.pumpAndSettle();

      expect(alerts.settingsOpened, 1);
    });

    testWidgets('no button when the permission is given', (
      WidgetTester tester,
    ) async {
      await _open(tester, alerts: FakeAlertPlatform());

      await tester.tap(find.byKey(textTvAlertsKey));
      await tester.pumpAndSettle();

      expect(find.byKey(textTvOpenSettingsKey), findsNothing);
    });

    testWidgets('turning them off asks for nothing', (
      WidgetTester tester,
    ) async {
      final FakeAlertPlatform alerts = FakeAlertPlatform();
      final List<BackgroundSettings> heard = await _open(
        tester,
        background: const BackgroundSettings(alerts: true),
        alerts: alerts,
      );

      await tester.tap(find.byKey(textTvAlertsKey));
      await tester.pumpAndSettle();

      expect(alerts.asked, 0);
      expect(heard.last.alerts, isFalse);
    });

    testWidgets('with them on, the page to watch is picked from a list', (
      WidgetTester tester,
    ) async {
      final List<BackgroundSettings> heard = await _open(
        tester,
        background: const BackgroundSettings(alerts: true),
      );
      await tester.scrollUntilVisible(find.byKey(textTvAlertPageKey), 200);

      await tester.tap(find.byKey(textTvAlertPageKey));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(textTvPickKey(300)));
      await tester.pumpAndSettle();

      expect(heard.last.alertPage, 300);
    });

    testWidgets('without a notification service the switch just switches', (
      WidgetTester tester,
    ) async {
      final List<BackgroundSettings> heard = await _open(tester);

      await tester.tap(find.byKey(textTvAlertsKey));
      await tester.pumpAndSettle();

      expect(heard.last.alerts, isTrue);
    });
  });
}
