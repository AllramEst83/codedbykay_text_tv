import 'package:codedbykay_text_tv/model/page_search.dart';
import 'package:codedbykay_text_tv/model/text_tv_page.dart';
import 'package:flutter_test/flutter_test.dart';

TextTvPage _page(int number, List<String> rows, {List<String>? second}) =>
    TextTvPage(number: number, parts: <List<String>>[rows, ?second]);

void main() {
  group('searchPages', () {
    final List<TextTvPage> pages = <TextTvPage>[
      _page(130, <String>[
        '130 SVT Text',
        'Skåne får mer snö i natt',
        'Vinter',
      ]),
      _page(104, <String>['104 SVT Text', 'Snö och blåst', 'Mer snö väntas']),
      _page(300, <String>['300 Sport', 'Fotboll: AIK vinner']),
    ];

    test('finds a word on a line, in any case', () {
      expect(searchPages(pages, 'FOTBOLL').map((SearchHit h) => h.page), <int>[
        300,
      ]);
    });

    test('å, ä and ö match a, a and o, both ways', () {
      expect(searchPages(pages, 'skane').single.page, 130);
      expect(searchPages(pages, 'blast').single.page, 104);
      expect(searchPages(pages, 'Snö').length, 2);
      expect(searchPages(pages, 'sno').length, 2);
    });

    test('every word has to be on the same line, in any order', () {
      expect(searchPages(pages, 'snö skåne').single.page, 130);
      expect(searchPages(pages, 'fotboll snö'), isEmpty);
    });

    test('more matching lines come first, then the lower page number', () {
      expect(searchPages(pages, 'snö').map((SearchHit h) => h.page), <int>[
        104,
        130,
      ]);
      expect(searchPages(pages, 'snö').first.matches, 2);
    });

    test('the hit shows the first matching line, tidied', () {
      final List<SearchHit> hits = searchPages(<TextTvPage>[
        _page(500, <String>['500', '   Hej    världen   ']),
      ], 'värld');

      expect(hits.single.line, 'Hej världen');
    });

    test('a page with several parts is listed once', () {
      final List<SearchHit> hits = searchPages(<TextTvPage>[
        _page(500, <String>['kö i stan'], second: <String>['kö på E4']),
      ], 'kö');

      expect(hits, hasLength(1));
      expect(hits.single.matches, 2);
    });

    test('too short or empty a query finds nothing', () {
      expect(searchPages(pages, ''), isEmpty);
      expect(searchPages(pages, '   '), isEmpty);
      expect(searchPages(pages, 's'), isEmpty);
    });

    test('never more than the most hits', () {
      final List<TextTvPage> many = <TextTvPage>[
        for (int i = 0; i < 100; i++) _page(200 + i, <String>['match $i']),
      ];

      expect(searchPages(many, 'match'), hasLength(maxSearchHits));
    });
  });
}
