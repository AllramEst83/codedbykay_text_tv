import 'package:codedbykay_text_tv/messages.dart';
import 'package:codedbykay_text_tv/model/text_tv_page.dart';
import 'package:codedbykay_text_tv/ui/text_tv_keys.dart';
import 'package:codedbykay_text_tv/ui/text_tv_screen.dart';
import 'package:codedbykay_text_tv/ui/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fakes/fake_text_tv_repository.dart';

Future<void> _open(WidgetTester tester) async {
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
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _openSettings(WidgetTester tester) async {
  await tester.tap(find.byKey(textTvSettingsKey));
  await tester.pumpAndSettle();
}

void main() {
  group('the settings page', () {
    testWidgets('opens from the gear button, and back returns', (
      WidgetTester tester,
    ) async {
      await _open(tester);
      expect(find.text(Messages.settingsTitle), findsNothing);

      await _openSettings(tester);
      expect(find.text(Messages.settingsTitle), findsOneWidget);

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

    testWidgets('says there is nothing to set yet', (
      WidgetTester tester,
    ) async {
      await _open(tester);
      await _openSettings(tester);

      expect(find.text(Messages.noSettings), findsOneWidget);
    });
  });
}
