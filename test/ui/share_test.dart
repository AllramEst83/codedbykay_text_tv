import 'package:codedbykay_text_tv/model/text_tv_page.dart';
import 'package:codedbykay_text_tv/ui/text_tv_keys.dart';
import 'package:codedbykay_text_tv/ui/text_tv_screen.dart';
import 'package:codedbykay_text_tv/ui/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fakes/fake_share_platform.dart';
import '../fakes/fake_text_tv_repository.dart';

FakeTextTvRepository _repository() => FakeTextTvRepository(<int, TextTvPage>{
  100: const TextTvPage(
    number: 100,
    parts: <List<String>>[
      <String>['100 SVT Text', 'Första', 'Andra'],
      <String>['100 del två', 'Tredje'],
    ],
    next: 101,
  ),
});

late List<String?> _clipboard;

Future<FakeSharePlatform> _open(
  WidgetTester tester, {
  bool withShare = true,
  FakeTextTvRepository? repository,
  Future<void> Function(WidgetTester tester)? beforeSheet,
}) async {
  _clipboard = <String?>[];
  tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
    SystemChannels.platform,
    (MethodCall call) async {
      if (call.method == 'Clipboard.setData') {
        _clipboard.add(
          (call.arguments as Map<Object?, Object?>)['text'] as String?,
        );
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
  tester.view
    ..physicalSize = const Size(800, 2400)
    ..devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final FakeSharePlatform share = FakeSharePlatform();
  await tester.pumpWidget(
    MaterialApp(
      theme: textTvTheme(),
      home: TextTvScreen(
        repository: repository ?? _repository(),
        share: withShare ? share : null,
      ),
    ),
  );
  await tester.pumpAndSettle();
  await beforeSheet?.call(tester);
  await tester.tap(find.byKey(textTvShareKey));
  await tester.pumpAndSettle();
  return share;
}

void main() {
  group('copy and share', () {
    testWidgets('COPY TEXT puts the page text on the clipboard and says so', (
      WidgetTester tester,
    ) async {
      await _open(tester);

      await tester.tap(find.byKey(textTvCopyTextKey));
      await tester.pumpAndSettle();

      expect(_clipboard, <String?>['100 SVT Text\nFörsta\nAndra']);
      expect(find.text('COPIED'), findsOneWidget);
      expect(find.byKey(textTvCopyTextKey), findsNothing, reason: 'sheet shut');
    });

    testWidgets('it copies the part on show', (WidgetTester tester) async {
      await _open(
        tester,
        beforeSheet: (WidgetTester t) async {
          await t.tap(find.byKey(textTvPartNextKey));
          await t.pumpAndSettle();
        },
      );

      await tester.tap(find.byKey(textTvCopyTextKey));
      await tester.pumpAndSettle();

      expect(_clipboard, <String?>['100 del två\nTredje']);
    });

    testWidgets('SHARE TEXT shares the page and its link', (
      WidgetTester tester,
    ) async {
      final FakeSharePlatform share = await _open(tester);

      await tester.tap(find.byKey(textTvShareTextKey));
      await tester.pumpAndSettle();

      expect(share.texts, hasLength(1));
      expect(
        share.texts.single.$1,
        '100 SVT Text\nFörsta\nAndra\n\nhttps://texttv.nu/100',
      );
      expect(share.texts.single.$2, 'Page 100');
    });

    testWidgets('SHARE LINK shares only the link', (WidgetTester tester) async {
      final FakeSharePlatform share = await _open(tester);

      await tester.tap(find.byKey(textTvShareLinkKey));
      await tester.pumpAndSettle();

      expect(share.texts.single.$1, 'https://texttv.nu/100');
    });

    testWidgets('with no share sheet on the phone, sharing does nothing', (
      WidgetTester tester,
    ) async {
      await _open(tester, withShare: false);

      await tester.tap(find.byKey(textTvShareTextKey));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });

    testWidgets('there is nothing to share while the page is not shown', (
      WidgetTester tester,
    ) async {
      tester.view
        ..physicalSize = const Size(800, 2400)
        ..devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp(
          theme: textTvTheme(),
          home: TextTvScreen(repository: FakeTextTvRepository()),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(textTvShareKey));
      await tester.pumpAndSettle();

      expect(find.byKey(textTvCopyTextKey), findsNothing);
    });
  });
}
