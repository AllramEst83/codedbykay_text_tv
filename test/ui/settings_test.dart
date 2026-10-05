import 'package:codedbykay_text_tv/messages.dart';
import 'package:codedbykay_text_tv/model/crt_settings.dart';
import 'package:codedbykay_text_tv/model/text_tv_page.dart';
import 'package:codedbykay_text_tv/ui/text_tv_keys.dart';
import 'package:codedbykay_text_tv/ui/text_tv_screen.dart';
import 'package:codedbykay_text_tv/ui/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fakes/fake_text_tv_repository.dart';

Future<void> _open(
  WidgetTester tester, {
  CrtSettings crt = CrtSettings.defaults,
  ValueChanged<CrtSettings>? onCrtChanged,
}) async {
  tester.view
    ..physicalSize = const Size(800, 2400)
    ..devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      theme: textTvTheme(),
      home: TextTvScreen(
        repository: FakeTextTvRepository(<int, TextTvPage>{
          100: const TextTvPage(
            number: 100,
            parts: <List<String>>[
              <String>['100 SVT Text', '', 'Hej'],
            ],
          ),
        }),
        crt: crt,
        onCrtChanged: onCrtChanged,
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _openSettings(WidgetTester tester) async {
  await tester.tap(find.byKey(textTvSettingsKey));
  await tester.pumpAndSettle();
}

Slider _slider(WidgetTester tester, Key key) => tester.widget<Slider>(
  find
          .descendant(of: find.byKey(key), matching: find.byType(Slider))
          .evaluate()
          .isEmpty
      ? find.byKey(key)
      : find.descendant(of: find.byKey(key), matching: find.byType(Slider)),
);

void main() {
  group('the settings page', () {
    testWidgets('opens from the gear button, and back returns', (
      WidgetTester tester,
    ) async {
      await _open(tester);
      expect(find.text(Messages.settingsTitle), findsNothing);

      await _openSettings(tester);
      expect(find.text(Messages.settingsTitle), findsOneWidget);
      expect(find.text(Messages.crtEffect), findsOneWidget);

      await tester.tap(find.byKey(textTvSettingsBackKey));
      await tester.pumpAndSettle();
      expect(find.text(Messages.settingsTitle), findsNothing);
      expect(find.byKey(textTvSettingsKey), findsOneWidget);
    });

    testWidgets('the system back button also leaves it, not the app', (
      WidgetTester tester,
    ) async {
      await _open(tester);
      await _openSettings(tester);

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();

      expect(find.text(Messages.settingsTitle), findsNothing);
      expect(find.byKey(textTvNumberKey), findsOneWidget);
    });

    testWidgets('the gear has a name for a screen reader', (
      WidgetTester tester,
    ) async {
      await _open(tester);

      expect(find.bySemanticsLabel(Messages.settings), findsOneWidget);
    });

    testWidgets('shows the switch off by default, sliders greyed', (
      WidgetTester tester,
    ) async {
      await _open(tester);
      await _openSettings(tester);

      expect(
        tester.widget<Switch>(find.byKey(textTvCrtSwitchKey)).value,
        isFalse,
      );
      for (final Key key in <Key>[
        textTvCrtCurveKey,
        textTvCrtDepthKey,
        textTvCrtPeriodKey,
      ]) {
        expect(_slider(tester, key).onChanged, isNull, reason: '$key');
      }
    });

    testWidgets('the switch turns the effect on, and reports it', (
      WidgetTester tester,
    ) async {
      final List<CrtSettings> heard = <CrtSettings>[];
      await _open(tester, onCrtChanged: heard.add);
      await _openSettings(tester);

      await tester.tap(find.byKey(textTvCrtSwitchKey));
      await tester.pumpAndSettle();

      expect(heard.last.enabled, isTrue);
      expect(
        tester.widget<Switch>(find.byKey(textTvCrtSwitchKey)).value,
        isTrue,
      );
      expect(_slider(tester, textTvCrtCurveKey).onChanged, isNotNull);
    });

    testWidgets('a slider changes its value, and reports it', (
      WidgetTester tester,
    ) async {
      final List<CrtSettings> heard = <CrtSettings>[];
      await _open(
        tester,
        crt: CrtSettings(enabled: true),
        onCrtChanged: heard.add,
      );
      await _openSettings(tester);

      await tester.drag(find.byKey(textTvCrtDepthKey), const Offset(2000, 0));
      await tester.pumpAndSettle();

      expect(heard.last.scanDepth, crtScanDepthMax);
      expect(heard.last.curve, CrtSettings.defaults.curve);
    });

    testWidgets('no slider can be dragged past its cap, either way', (
      WidgetTester tester,
    ) async {
      final List<CrtSettings> heard = <CrtSettings>[];
      await _open(
        tester,
        crt: CrtSettings(enabled: true),
        onCrtChanged: heard.add,
      );
      await _openSettings(tester);

      for (final Key key in <Key>[
        textTvCrtCurveKey,
        textTvCrtDepthKey,
        textTvCrtPeriodKey,
      ]) {
        await tester.drag(find.byKey(key), const Offset(5000, 0));
        await tester.pumpAndSettle();
        await tester.drag(find.byKey(key), const Offset(-9000, 0));
        await tester.pumpAndSettle();
        await tester.drag(find.byKey(key), const Offset(5000, 0));
        await tester.pumpAndSettle();
      }

      final CrtSettings last = heard.last;
      expect(last.curve, lessThanOrEqualTo(crtCurveMax));
      expect(last.scanDepth, lessThanOrEqualTo(crtScanDepthMax));
      expect(last.scanPeriod, lessThanOrEqualTo(crtScanPeriodMax));
      expect(last.scanPeriod, greaterThanOrEqualTo(crtScanPeriodMin));
      for (final CrtSettings s in heard) {
        expect(s.curve, inInclusiveRange(0, crtCurveMax));
        expect(s.scanDepth, inInclusiveRange(0, crtScanDepthMax));
        expect(
          s.scanPeriod,
          inInclusiveRange(crtScanPeriodMin, crtScanPeriodMax),
        );
      }
    });

    testWidgets('RESET puts the looks back but keeps the effect on', (
      WidgetTester tester,
    ) async {
      final List<CrtSettings> heard = <CrtSettings>[];
      await _open(
        tester,
        crt: CrtSettings(
          enabled: true,
          curve: 0.06,
          scanDepth: 0.35,
          scanPeriod: 5,
        ),
        onCrtChanged: heard.add,
      );
      await _openSettings(tester);

      await tester.tap(find.byKey(textTvCrtResetKey));
      await tester.pumpAndSettle();

      expect(heard.last, CrtSettings.defaults.copyWith(enabled: true));
    });

    testWidgets('shows a preview', (WidgetTester tester) async {
      await _open(tester);
      await _openSettings(tester);

      expect(find.byKey(textTvCrtPreviewKey), findsOneWidget);
    });

    testWidgets('opens with the saved settings', (WidgetTester tester) async {
      await _open(tester, crt: CrtSettings(enabled: true, scanPeriod: 4));
      await _openSettings(tester);

      expect(
        tester.widget<Switch>(find.byKey(textTvCrtSwitchKey)).value,
        isTrue,
      );
      expect(_slider(tester, textTvCrtPeriodKey).value, 4);
    });
  });
}
