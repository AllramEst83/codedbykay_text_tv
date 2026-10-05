import 'package:codedbykay_text_tv/l10n/l10n.dart';
import 'package:codedbykay_text_tv/model/network_failure.dart';
import 'package:codedbykay_text_tv/model/text_tv_page.dart';
import 'package:codedbykay_text_tv/services/shortcut_service.dart';
import 'package:codedbykay_text_tv/ui/text_tv_keys.dart';
import 'package:codedbykay_text_tv/ui/text_tv_screen.dart';
import 'package:codedbykay_text_tv/ui/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fakes/fake_shortcut_platform.dart';
import '../fakes/fake_text_tv_repository.dart';

FakeTextTvRepository _repository() => FakeTextTvRepository(<int, TextTvPage>{
  100: const TextTvPage(
    number: 100,
    parts: <List<String>>[
      <String>['100 SVT Text', 'Hej'],
      <String>['100 del två', 'Mer'],
    ],
    next: 101,
  ),
});

Future<void> _open(
  WidgetTester tester, {
  required Locale locale,
  FakeTextTvRepository? repository,
  ShortcutService? shortcuts,
}) async {
  tester.view
    ..physicalSize = const Size(800, 2400)
    ..devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      theme: textTvTheme(),
      home: TextTvScreen(
        repository: repository ?? _repository(),
        shortcuts: shortcuts,
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('on a Swedish phone the chips and the title are Swedish', (
    WidgetTester tester,
  ) async {
    await _open(tester, locale: const Locale('sv'));

    expect(find.text('TEXT-TV'), findsOneWidget);
    expect(find.text('100 NYHETER'), findsOneWidget);
    expect(find.text('400 VÄDER'), findsOneWidget);
    expect(find.text('700 INNEHÅLL'), findsOneWidget);
    expect(find.text('100 NEWS'), findsNothing);
  });

  testWidgets('on an English phone they are English', (
    WidgetTester tester,
  ) async {
    await _open(tester, locale: const Locale('en'));

    expect(find.text('TEXT TV'), findsOneWidget);
    expect(find.text('100 NEWS'), findsOneWidget);
  });

  testWidgets('the icons speak Swedish to a screen reader', (
    WidgetTester tester,
  ) async {
    final SemanticsHandle handle = tester.ensureSemantics();
    await _open(tester, locale: const Locale('sv'));

    expect(find.bySemanticsLabel('Sök'), findsOneWidget);
    expect(find.bySemanticsLabel('Läsläge'), findsOneWidget);
    expect(find.bySemanticsLabel('Inställningar'), findsOneWidget);
    expect(find.bySemanticsLabel('Uppdatera sidan'), findsOneWidget);
    expect(find.bySemanticsLabel('Kopiera eller dela sidan'), findsOneWidget);
    handle.dispose();
  });

  testWidgets('the part bar says DEL', (WidgetTester tester) async {
    await _open(tester, locale: const Locale('sv'));

    expect(find.text('DEL 1/2'), findsOneWidget);
  });

  testWidgets('a failure is worded in Swedish', (WidgetTester tester) async {
    final FakeTextTvRepository repository = _repository()
      ..failure = const TextTvFailed(NetworkFailure.offline);
    await _open(tester, locale: const Locale('sv'), repository: repository);

    expect(find.text('INGEN ANSLUTNING. KOLLA NÄTVERKET.'), findsOneWidget);
    expect(find.text('FÖRSÖK IGEN'), findsOneWidget);
  });

  testWidgets('the settings page is Swedish', (WidgetTester tester) async {
    await _open(tester, locale: const Locale('sv'));

    await tester.tap(find.byKey(textTvSettingsKey));
    await tester.pumpAndSettle();

    expect(find.text('INSTÄLLNINGAR'), findsOneWidget);
    expect(find.text('FAVORITER'), findsOneWidget);
    expect(find.text('ÅTERSTÄLL FAVORITER'), findsOneWidget);
    expect(find.text('0 AV 24 SPARADE'), findsNothing);
    await tester.scrollUntilVisible(find.byKey(textTvAboutPrivacyKey), 200);
    expect(find.textContaining('Inget konto'), findsOneWidget);
    expect(find.text('OM APPEN'), findsOneWidget);
    expect(find.text('6 AV 24 SPARADE'), findsOneWidget);
  });

  testWidgets('the search sheet is Swedish', (WidgetTester tester) async {
    await _open(tester, locale: const Locale('sv'));

    await tester.tap(find.byKey(textTvSearchKey));
    await tester.pumpAndSettle();

    expect(find.text('SÖK'), findsOneWidget);
    expect(find.text('SÖKER BARA I SIDOR DU HAR LÄST.'), findsOneWidget);
  });

  group('the icon shortcuts', () {
    testWidgets('are titled in Swedish on a Swedish phone', (
      WidgetTester tester,
    ) async {
      final FakeShortcutPlatform platform = FakeShortcutPlatform();
      final ShortcutService service = ShortcutService(platform);
      await service.start();

      await _open(tester, locale: const Locale('sv'), shortcuts: service);

      expect(platform.current.map((e) => e.title), <String>[
        '100 NYHETER',
        '101 INRIKES',
        '104 UTRIKES',
        '300 SPORT',
      ]);
    });

    testWidgets('are titled in English on an English phone', (
      WidgetTester tester,
    ) async {
      final FakeShortcutPlatform platform = FakeShortcutPlatform();
      final ShortcutService service = ShortcutService(platform);
      await service.start();

      await _open(tester, locale: const Locale('en'), shortcuts: service);

      expect(platform.current.first.title, '100 NEWS');
    });

    testWidgets('are told again when the phone changes language', (
      WidgetTester tester,
    ) async {
      final FakeShortcutPlatform platform = FakeShortcutPlatform();
      final ShortcutService service = ShortcutService(platform);
      await service.start();
      await _open(tester, locale: const Locale('en'), shortcuts: service);
      expect(platform.current.first.title, '100 NEWS');

      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('sv'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          theme: textTvTheme(),
          home: TextTvScreen(repository: _repository(), shortcuts: service),
        ),
      );
      await tester.pumpAndSettle();

      expect(platform.current.first.title, '100 NYHETER');
    });
  });

  testWidgets('a phone in another language gets English', (
    WidgetTester tester,
  ) async {
    await _open(tester, locale: const Locale('fi'));

    expect(find.text('100 NEWS'), findsOneWidget);
  });
}
