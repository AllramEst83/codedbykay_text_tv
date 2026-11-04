import 'package:codedbykay_text_tv/model/controls_settings.dart';
import 'package:codedbykay_text_tv/model/text_tv_page.dart';
import 'package:codedbykay_text_tv/model/text_tv_session.dart';
import 'package:codedbykay_text_tv/ui/text_tv_keys.dart';
import 'package:codedbykay_text_tv/ui/text_tv_screen.dart';
import 'package:codedbykay_text_tv/ui/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fakes/fake_text_tv_repository.dart';

TextTvPage _page(int n, {int parts = 1}) => TextTvPage(
  number: n,
  parts: <List<String>>[
    for (int i = 0; i < parts; i++) <String>['$n part $i'],
  ],
);

/// Opens the screen on page 100 and returns the haptic kinds as they fire.
Future<List<String>> _pump(
  WidgetTester tester, {
  bool quick = true,
  int parts = 1,
}) async {
  final List<String> felt = <String>[];
  tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
    SystemChannels.platform,
    (MethodCall call) async {
      if (call.method == 'HapticFeedback.vibrate') {
        felt.add(call.arguments as String);
      }
      return null;
    },
  );
  addTearDown(
    () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      null,
    ),
  );
  await tester.pumpWidget(
    MaterialApp(
      theme: textTvTheme(),
      home: TextTvScreen(
        repository: FakeTextTvRepository(<int, TextTvPage>{
          for (final int n in <int>[100, 101, 123]) n: _page(n, parts: parts),
        }),
        initial: const TextTvSession(page: 100),
        controls: ControlsSettings(quickEntry: quick),
      ),
    ),
  );
  await tester.pumpAndSettle();
  felt.clear();
  return felt;
}

const String _tick = 'HapticFeedbackType.selectionClick';
const String _press = 'HapticFeedbackType.lightImpact';
const String _confirm = 'HapticFeedbackType.mediumImpact';

void main() {
  group('haptic feedback', () {
    testWidgets('each digit ticks and the third confirms the page', (
      WidgetTester tester,
    ) async {
      final List<String> felt = await _pump(tester);

      await tester.tap(find.byKey(textTvDigitKey(1)));
      await tester.tap(find.byKey(textTvDigitKey(2)));
      expect(felt, <String>[_tick, _tick]);
      await tester.tap(find.byKey(textTvDigitKey(3)));
      await tester.pumpAndSettle();

      expect(felt, <String>[_tick, _tick, _confirm]);
    });

    testWidgets('a greyed key does not tick', (WidgetTester tester) async {
      final List<String> felt = await _pump(tester);

      await tester.tap(find.byKey(textTvDigitKey(0)), warnIfMissed: false);

      expect(felt, isEmpty);
    });

    testWidgets('the classic pad ticks on digits and DEL', (
      WidgetTester tester,
    ) async {
      final List<String> felt = await _pump(tester, quick: false);

      await tester.tap(find.byKey(textTvNumberKey));
      await tester.tap(find.byKey(textTvDigitKey(1)));
      await tester.tap(find.byKey(textTvDeleteKey));

      expect(felt, <String>[_tick, _tick, _tick]);
    });

    testWidgets('opening a page by the arrow gives a press', (
      WidgetTester tester,
    ) async {
      final List<String> felt = await _pump(tester);

      await tester.tap(find.byKey(textTvNextKey));
      await tester.pumpAndSettle();

      expect(felt, <String>[_press]);
    });

    testWidgets('stepping to another part ticks', (WidgetTester tester) async {
      final List<String> felt = await _pump(tester, parts: 2);

      await tester.tap(find.byKey(textTvPartNextKey));
      await tester.pump();

      expect(felt, <String>[_tick]);
    });

    testWidgets('starring a page gives a press', (WidgetTester tester) async {
      final List<String> felt = await _pump(tester);

      await tester.tap(find.byKey(textTvStarKey));
      await tester.pump();

      expect(felt, <String>[_press]);
    });
  });
}
