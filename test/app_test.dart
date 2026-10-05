import 'package:codedbykay_text_tv/app.dart';
import 'package:codedbykay_text_tv/messages.dart';
import 'package:codedbykay_text_tv/model/text_tv_page.dart';
import 'package:codedbykay_text_tv/ui/text_tv_screen.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fakes/fake_text_tv_repository.dart';

void main() {
  testWidgets('the app opens straight on the Text TV viewer, page 100', (
    WidgetTester tester,
  ) async {
    final FakeTextTvRepository repository = FakeTextTvRepository(
      <int, TextTvPage>{
        100: const TextTvPage(
          number: 100,
          parts: <List<String>>[
            <String>['100 SVT Text'],
          ],
        ),
      },
    );

    await tester.pumpWidget(TextTvApp(repository: repository));
    await tester.pumpAndSettle();

    expect(find.byType(TextTvScreen), findsOneWidget);
    expect(find.text(Messages.title), findsOneWidget);
    expect(repository.requests, <(int, bool)>[(100, false)]);
  });
}
