import 'dart:ui';

import 'package:codedbykay_text_tv/app.dart';
import 'package:codedbykay_text_tv/model/language_settings.dart';
import 'package:codedbykay_text_tv/model/text_tv_page.dart';
import 'package:codedbykay_text_tv/ui/text_tv_keys.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fakes/fake_text_tv_repository.dart';

FakeTextTvRepository _repository() => FakeTextTvRepository(<int, TextTvPage>{
  100: const TextTvPage(
    number: 100,
    parts: <List<String>>[
      <String>['100 SVT Text', 'Hej'],
    ],
  ),
});

/// The whole app, on a phone set to [phone], saved with [language].
Future<List<LanguageSettings>> _open(
  WidgetTester tester, {
  required Locale phone,
  LanguageSettings language = LanguageSettings.defaults,
}) async {
  tester.view
    ..physicalSize = const Size(800, 3000)
    ..devicePixelRatio = 1;
  tester.platformDispatcher.localesTestValue = <Locale>[phone];
  addTearDown(() {
    tester.view.reset();
    tester.platformDispatcher.clearLocalesTestValue();
  });
  final List<LanguageSettings> heard = <LanguageSettings>[];
  await tester.pumpWidget(
    TextTvApp(
      repository: _repository(),
      language: language,
      onLanguageChanged: heard.add,
    ),
  );
  await tester.pumpAndSettle();
  return heard;
}

Future<void> _openSettings(WidgetTester tester) async {
  await tester.tap(find.byKey(textTvSettingsKey));
  await tester.pumpAndSettle();
}

void main() {
  group('SYSTEM follows the phone', () {
    testWidgets('a Swedish phone gets Swedish', (WidgetTester tester) async {
      await _open(tester, phone: const Locale('sv', 'SE'));

      expect(find.text('TEXT-TV'), findsOneWidget);
    });

    testWidgets('an English phone gets English', (WidgetTester tester) async {
      await _open(tester, phone: const Locale('en', 'US'));

      expect(find.text('TEXT TV'), findsOneWidget);
    });

    testWidgets('a Danish phone gets English', (WidgetTester tester) async {
      await _open(tester, phone: const Locale('da', 'DK'));

      expect(find.text('TEXT TV'), findsOneWidget);
      expect(find.text('100 NEWS'), findsOneWidget);
    });
  });

  group('a chosen language wins over the phone', () {
    testWidgets('Swedish on an English phone', (WidgetTester tester) async {
      await _open(
        tester,
        phone: const Locale('en'),
        language: const LanguageSettings(language: AppLanguage.swedish),
      );

      expect(find.text('TEXT-TV'), findsOneWidget);
      expect(find.text('100 NYHETER'), findsOneWidget);
    });

    testWidgets('English on a Swedish phone', (WidgetTester tester) async {
      await _open(
        tester,
        phone: const Locale('sv'),
        language: const LanguageSettings(language: AppLanguage.english),
      );

      expect(find.text('TEXT TV'), findsOneWidget);
    });
  });

  group('the language group in settings', () {
    testWidgets('has the three choices and a note about SYSTEM', (
      WidgetTester tester,
    ) async {
      await _open(tester, phone: const Locale('en'));
      await _openSettings(tester);

      expect(find.byKey(textTvSettingsGroupKey('language')), findsOneWidget);
      expect(find.text('LANGUAGE'), findsOneWidget);
      for (final AppLanguage l in AppLanguage.values) {
        expect(find.byKey(textTvLanguageKey(l)), findsOneWidget);
      }
      expect(find.text('SYSTEM'), findsOneWidget);
      expect(find.text('SVENSKA'), findsOneWidget);
      expect(find.text('ENGLISH'), findsWidgets);
      expect(
        find.textContaining('If the phone uses a language this app does not'),
        findsOneWidget,
      );
    });

    testWidgets('choosing Svenska switches the app at once, and says so', (
      WidgetTester tester,
    ) async {
      final List<LanguageSettings> heard = await _open(
        tester,
        phone: const Locale('en'),
      );
      await _openSettings(tester);

      await tester.tap(find.byKey(textTvLanguageKey(AppLanguage.swedish)));
      await tester.pumpAndSettle();

      expect(heard.last.language, AppLanguage.swedish);
      expect(find.text('INSTÄLLNINGAR'), findsOneWidget);
      expect(find.text('SPRÅK'), findsOneWidget);
      expect(find.textContaining('Om telefonen använder'), findsOneWidget);

      await tester.tap(find.byKey(textTvSettingsBackKey));
      await tester.pumpAndSettle();
      expect(find.text('TEXT-TV'), findsOneWidget);
      expect(find.text('100 NYHETER'), findsOneWidget);
    });

    testWidgets('and back to English', (WidgetTester tester) async {
      final List<LanguageSettings> heard = await _open(
        tester,
        phone: const Locale('sv'),
        language: const LanguageSettings(language: AppLanguage.swedish),
      );
      await _openSettings(tester);

      await tester.tap(find.byKey(textTvLanguageKey(AppLanguage.english)));
      await tester.pumpAndSettle();

      expect(heard.last.language, AppLanguage.english);
      expect(find.text('SETTINGS'), findsOneWidget);
    });

    testWidgets('SYSTEM goes back to the phone\'s language', (
      WidgetTester tester,
    ) async {
      final List<LanguageSettings> heard = await _open(
        tester,
        phone: const Locale('da'),
        language: const LanguageSettings(language: AppLanguage.swedish),
      );
      await _openSettings(tester);
      expect(find.text('INSTÄLLNINGAR'), findsOneWidget);

      await tester.tap(find.byKey(textTvLanguageKey(AppLanguage.system)));
      await tester.pumpAndSettle();

      expect(heard.last.language, AppLanguage.system);
      expect(
        find.text('SETTINGS'),
        findsOneWidget,
        reason: 'Danish gets English',
      );
    });

    testWidgets('the chosen one is marked for a screen reader', (
      WidgetTester tester,
    ) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await _open(
        tester,
        phone: const Locale('en'),
        language: const LanguageSettings(language: AppLanguage.swedish),
      );
      await _openSettings(tester);

      expect(
        tester
            .getSemantics(find.byKey(textTvLanguageKey(AppLanguage.swedish)))
            .getSemanticsData()
            .flagsCollection
            .isSelected,
        isNotNull,
      );
      handle.dispose();
    });

    testWidgets('choosing what is already chosen reports nothing', (
      WidgetTester tester,
    ) async {
      final List<LanguageSettings> heard = await _open(
        tester,
        phone: const Locale('en'),
      );
      await _openSettings(tester);

      await tester.tap(find.byKey(textTvLanguageKey(AppLanguage.system)));
      await tester.pumpAndSettle();

      expect(heard, isEmpty);
    });
  });
}
