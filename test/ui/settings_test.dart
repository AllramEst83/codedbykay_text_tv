import 'package:codedbykay_text_tv/messages.dart';
import 'package:codedbykay_text_tv/model/controls_settings.dart';
import 'package:codedbykay_text_tv/model/crt_settings.dart';
import 'package:codedbykay_text_tv/model/styled_text.dart';
import 'package:codedbykay_text_tv/model/text_tv_page.dart';
import 'package:codedbykay_text_tv/ui/text_tv_keys.dart';
import 'package:codedbykay_text_tv/ui/text_tv_screen.dart';
import 'package:codedbykay_text_tv/ui/theme.dart';
import 'package:codedbykay_text_tv/ui/tv_row.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fakes/fake_text_tv_repository.dart';

Future<void> _open(
  WidgetTester tester, {
  CrtSettings crt = CrtSettings.defaults,
  ValueChanged<CrtSettings>? onCrtChanged,
  ControlsSettings controls = ControlsSettings.defaults,
  ValueChanged<ControlsSettings>? onControlsChanged,
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
        controls: controls,
        onControlsChanged: onControlsChanged,
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

  group('the controls setting', () {
    testWidgets('is off by default: the classic controls', (
      WidgetTester tester,
    ) async {
      await _open(tester);

      // The classic controls: shortcuts, and no always-on pad.
      expect(find.byKey(textTvChipKey(300)), findsOneWidget);
      expect(find.byKey(textTvDigitKey(5)), findsNothing);

      await _openSettings(tester);
      expect(
        tester.widget<Switch>(find.byKey(textTvQuickEntryKey)).value,
        isFalse,
      );
    });

    testWidgets('turning it on shows the always-on pad, and reports it', (
      WidgetTester tester,
    ) async {
      final List<ControlsSettings> heard = <ControlsSettings>[];
      await _open(tester, onControlsChanged: heard.add);
      await _openSettings(tester);

      await tester.tap(find.byKey(textTvQuickEntryKey));
      await tester.pumpAndSettle();
      expect(heard.last, const ControlsSettings(quickEntry: true));

      await tester.tap(find.byKey(textTvSettingsBackKey));
      await tester.pumpAndSettle();
      expect(find.byKey(textTvDigitKey(5)), findsOneWidget);
    });

    testWidgets('turning it off again brings back the tap-the-number pad', (
      WidgetTester tester,
    ) async {
      final List<ControlsSettings> heard = <ControlsSettings>[];
      await _open(
        tester,
        controls: const ControlsSettings(quickEntry: true),
        onControlsChanged: heard.add,
      );
      expect(find.byKey(textTvDigitKey(5)), findsOneWidget);
      await _openSettings(tester);

      await tester.tap(find.byKey(textTvQuickEntryKey));
      await tester.pumpAndSettle();
      expect(heard.last, const ControlsSettings());

      await tester.tap(find.byKey(textTvSettingsBackKey));
      await tester.pumpAndSettle();
      expect(find.byKey(textTvDigitKey(5)), findsNothing);
      expect(find.byKey(textTvChipKey(300)), findsOneWidget);

      await tester.tap(find.byKey(textTvNumberKey));
      await tester.pump();
      expect(find.byKey(textTvDigitKey(5)), findsOneWidget);
      expect(find.byKey(textTvDeleteKey), findsOneWidget);
    });

    testWidgets('opens with the saved setting', (WidgetTester tester) async {
      await _open(tester, controls: const ControlsSettings(quickEntry: true));
      await _openSettings(tester);

      expect(
        tester.widget<Switch>(find.byKey(textTvQuickEntryKey)).value,
        isTrue,
      );
    });

    testWidgets('switching drops a half-typed number', (
      WidgetTester tester,
    ) async {
      await _open(tester, controls: const ControlsSettings(quickEntry: true));
      await tester.tap(find.byKey(textTvDigitKey(3)));
      await tester.pump();
      await _openSettings(tester);

      await tester.tap(find.byKey(textTvQuickEntryKey));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(textTvSettingsBackKey));
      await tester.pumpAndSettle();

      expect(
        find.descendant(
          of: find.byKey(textTvNumberKey),
          matching: find.text('100'),
        ),
        findsOneWidget,
      );
    });
  });

  group('the groups of settings', () {
    const List<String> ids = <String>[
      'controls',
      'favourites',
      'refresh',
      'crt',
    ];

    testWidgets('are three panels, each with a named header bar', (
      WidgetTester tester,
    ) async {
      await _open(tester);
      await _openSettings(tester);

      for (final String id in ids) {
        expect(
          find.byKey(textTvSettingsGroupKey(id)),
          findsOneWidget,
          reason: id,
        );
        expect(
          find.byKey(textTvSettingsHeaderKey(id)),
          findsOneWidget,
          reason: id,
        );
      }
      for (final (String id, String title) in <(String, String)>[
        ('controls', Messages.sectionControls),
        ('favourites', Messages.sectionFavourites),
        ('refresh', Messages.sectionRefresh),
        ('crt', Messages.sectionCrt),
      ]) {
        expect(
          find.descendant(
            of: find.byKey(textTvSettingsHeaderKey(id)),
            matching: find.text(title),
          ),
          findsOneWidget,
          reason: id,
        );
      }
    });

    testWidgets('each has its own settings inside it, and only those', (
      WidgetTester tester,
    ) async {
      await _open(tester);
      await _openSettings(tester);
      Finder inside(String id, Key key) => find.descendant(
        of: find.byKey(textTvSettingsGroupKey(id)),
        matching: find.byKey(key),
      );

      expect(inside('controls', textTvQuickEntryKey), findsOneWidget);
      expect(inside('refresh', textTvAutoRefreshKey), findsOneWidget);
      for (final Key key in <Key>[
        textTvCrtSwitchKey,
        textTvCrtCurveKey,
        textTvCrtDepthKey,
        textTvCrtPeriodKey,
        textTvCrtResetKey,
        textTvCrtPreviewKey,
      ]) {
        expect(inside('crt', key), findsOneWidget, reason: '$key');
        expect(inside('controls', key), findsNothing, reason: '$key');
        expect(inside('refresh', key), findsNothing, reason: '$key');
      }
      expect(inside('refresh', textTvQuickEntryKey), findsNothing);
      expect(inside('crt', textTvAutoRefreshKey), findsNothing);
    });

    testWidgets('are framed, with a header bar in teletext blue', (
      WidgetTester tester,
    ) async {
      await _open(tester);
      await _openSettings(tester);

      for (final String id in ids) {
        final Container group = tester.widget<Container>(
          find.byKey(textTvSettingsGroupKey(id)),
        );
        final BoxDecoration frame = group.decoration! as BoxDecoration;
        expect(frame.border, isNotNull, reason: '$id has a frame');

        final Container header = tester.widget<Container>(
          find.byKey(textTvSettingsHeaderKey(id)),
        );
        expect(header.color, tvColorOf(TvColor.blue), reason: '$id header');
      }
    });

    testWidgets('are clearly apart: a gap between one panel and the next', (
      WidgetTester tester,
    ) async {
      await _open(tester);
      await _openSettings(tester);

      for (int i = 0; i < ids.length - 1; i++) {
        final Rect above = tester.getRect(
          find.byKey(textTvSettingsGroupKey(ids[i])),
        );
        final Rect below = tester.getRect(
          find.byKey(textTvSettingsGroupKey(ids[i + 1])),
        );

        expect(
          below.top - above.bottom,
          greaterThanOrEqualTo(TvMetrics.margin * 2 - 0.5),
        );
        expect(above.overlaps(below), isFalse);
      }
    });

    testWidgets('panels use the whole width, so their frames line up', (
      WidgetTester tester,
    ) async {
      await _open(tester);
      await _openSettings(tester);

      final List<Rect> rects = <Rect>[
        for (final String id in ids)
          tester.getRect(find.byKey(textTvSettingsGroupKey(id))),
      ];
      for (final Rect r in rects) {
        expect(r.left, rects.first.left);
        expect(r.width, rects.first.width);
      }
    });

    testWidgets('headers are announced as headers to a screen reader', (
      WidgetTester tester,
    ) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await _open(tester);
      await _openSettings(tester);

      for (final String id in ids) {
        expect(
          tester.getSemantics(find.byKey(textTvSettingsHeaderKey(id))),
          matchesSemantics(isHeader: true, label: _title(id)),
          reason: id,
        );
      }
      handle.dispose();
    });
  });
}

String _title(String id) => switch (id) {
  'controls' => Messages.sectionControls,
  'favourites' => Messages.sectionFavourites,
  'refresh' => Messages.sectionRefresh,
  _ => Messages.sectionCrt,
};
