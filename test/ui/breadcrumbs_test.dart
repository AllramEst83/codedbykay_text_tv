import 'package:codedbykay_text_tv/model/controls_settings.dart';
import 'package:codedbykay_text_tv/model/text_tv_page.dart';
import 'package:codedbykay_text_tv/model/text_tv_session.dart';
import 'package:codedbykay_text_tv/ui/text_tv_keys.dart';
import 'package:codedbykay_text_tv/ui/text_tv_screen.dart';
import 'package:codedbykay_text_tv/ui/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fakes/english.dart';
import '../fakes/fake_text_tv_repository.dart';

TextTvPage _page(int n, [List<Crumb>? crumbs]) => TextTvPage(
  number: n,
  parts: <List<String>>[
    <String>['$n SVT Text', 'Sida $n'],
  ],
  previous: n - 1,
  next: n + 1,
  breadcrumbs: crumbs,
);

FakeTextTvRepository _repository() => FakeTextTvRepository(<int, TextTvPage>{
  100: _page(100, const <Crumb>[Crumb('Hem', 100)]),
  300: _page(300, const <Crumb>[Crumb('Hem', 100), Crumb('Sport', 300)]),
  330: _page(330, const <Crumb>[
    Crumb('Hem', 100),
    Crumb('Sport', 300),
    Crumb('Resultatbörsen', 330),
  ]),
  377: _page(377, const <Crumb>[
    Crumb('Hem', 100),
    Crumb('Sport', 300),
    Crumb('Resultatbörsen', 330),
    Crumb('Målservice', 377),
  ]),
  555: _page(555),
});

Future<List<ControlsSettings>> _open(
  WidgetTester tester, {
  int start = 377,
  ControlsSettings controls = ControlsSettings.defaults,
  Size size = const Size(800, 3000),
}) async {
  tester.view
    ..physicalSize = size
    ..devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final List<ControlsSettings> heard = <ControlsSettings>[];
  await tester.pumpWidget(
    MaterialApp(
      theme: textTvTheme(),
      home: TextTvScreen(
        repository: _repository(),
        initial: TextTvSession(page: start),
        controls: controls,
        onControlsChanged: heard.add,
      ),
    ),
  );
  await tester.pumpAndSettle();
  return heard;
}

Finder _number(String text) =>
    find.descendant(of: find.byKey(textTvNumberKey), matching: find.text(text));

void main() {
  group('the breadcrumbs', () {
    testWidgets('show the way down to the page, the first step as HOME', (
      WidgetTester tester,
    ) async {
      await _open(tester);

      expect(find.byKey(textTvBreadcrumbsKey), findsOneWidget);
      for (final String step in <String>[
        'HOME',
        'SPORT',
        'RESULTATBÖRSEN',
        'MÅLSERVICE',
      ]) {
        expect(find.text(step), findsOneWidget, reason: step);
      }
    });

    testWidgets('a tap on a step goes up to that page', (
      WidgetTester tester,
    ) async {
      await _open(tester);

      await tester.tap(find.byKey(textTvCrumbKey(330)));
      await tester.pumpAndSettle();

      expect(_number('330'), findsOneWidget);
    });

    testWidgets('all the way up to the start page', (
      WidgetTester tester,
    ) async {
      await _open(tester);

      await tester.tap(find.byKey(textTvCrumbKey(100)));
      await tester.pumpAndSettle();

      expect(_number('100'), findsOneWidget);
    });

    testWidgets('the last step is the page itself: yellow, and not a button', (
      WidgetTester tester,
    ) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await _open(tester);

      final Text last = tester.widget<Text>(find.text('MÅLSERVICE'));
      expect(last.style?.color, TvColors.highlight);
      expect(
        tester
            .getSemantics(find.byKey(textTvCrumbKey(377)))
            .getSemanticsData()
            .flagsCollection
            .isButton,
        isFalse,
      );
      handle.dispose();
    });

    testWidgets('a step can be reached by a screen reader as a button', (
      WidgetTester tester,
    ) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await _open(tester);

      expect(
        find.bySemanticsLabel('SPORT. ${en.pageLabel(300)}'),
        findsOneWidget,
      );
      expect(find.bySemanticsLabel(en.crumbsLabel), findsOneWidget);
      handle.dispose();
    });

    testWidgets('follow the page as the reader goes to another', (
      WidgetTester tester,
    ) async {
      await _open(tester, start: 300);
      expect(find.text('RESULTATBÖRSEN'), findsNothing);

      await tester.tap(find.byKey(textTvNextKey));
      await tester.pumpAndSettle();

      // 301 is not served: its crumbs are gone with it.
      expect(find.byKey(textTvBreadcrumbsKey), findsNothing);
    });

    testWidgets('are not there for a page that has no path, or only one step', (
      WidgetTester tester,
    ) async {
      await _open(tester, start: 555);
      expect(find.byKey(textTvBreadcrumbsKey), findsNothing);

      await _open(tester, start: 100);
      expect(find.byKey(textTvBreadcrumbsKey), findsNothing);
    });

    testWidgets('can be switched off, and then take no room', (
      WidgetTester tester,
    ) async {
      await _open(tester, controls: const ControlsSettings(breadcrumbs: false));

      expect(find.byKey(textTvBreadcrumbsKey), findsNothing);
    });

    testWidgets('a long path scrolls and shows its end, the page', (
      WidgetTester tester,
    ) async {
      await _open(tester, size: const Size(300, 3000));

      expect(tester.takeException(), isNull);
      expect(find.byKey(textTvCrumbKey(377)), findsOneWidget);
      expect(
        tester.getTopRight(find.byKey(textTvCrumbKey(377))).dx,
        lessThanOrEqualTo(300),
      );
    });
  });

  group('in settings', () {
    testWidgets('a switch turns them off and on and says so', (
      WidgetTester tester,
    ) async {
      final List<ControlsSettings> heard = await _open(tester);
      await tester.tap(find.byKey(textTvSettingsKey));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.byKey(textTvBreadcrumbsSwitchKey),
        200,
      );
      expect(
        tester.widget<Switch>(find.byKey(textTvBreadcrumbsSwitchKey)).value,
        isTrue,
      );

      await tester.tap(find.byKey(textTvBreadcrumbsSwitchKey));
      await tester.pumpAndSettle();

      expect(heard.last.breadcrumbs, isFalse);
      await tester.tap(find.byKey(textTvSettingsBackKey));
      await tester.pumpAndSettle();
      expect(find.byKey(textTvBreadcrumbsKey), findsNothing);
    });
  });

  group('ControlsSettings with breadcrumbs', () {
    test('start on', () {
      expect(const ControlsSettings().breadcrumbs, isTrue);
    });

    test('survive a round trip', () {
      const ControlsSettings s = ControlsSettings(
        quickEntry: true,
        breadcrumbs: false,
      );

      expect(ControlsSettings.decode(s.encode()), s);
    });

    test('a save from before they existed has them on', () {
      expect(
        ControlsSettings.decode('{"quickEntry": true}').breadcrumbs,
        isTrue,
      );
      expect(ControlsSettings.decode('{"breadcrumbs": 3}').breadcrumbs, isTrue);
    });

    test('are part of equality', () {
      expect(
        const ControlsSettings(),
        isNot(const ControlsSettings(breadcrumbs: false)),
      );
      expect(
        const ControlsSettings(breadcrumbs: false).hashCode,
        isNot(const ControlsSettings().hashCode),
      );
    });
  });
}
