import 'dart:io';

import 'package:codedbykay_text_tv/model/reader_content.dart';
import 'package:codedbykay_text_tv/model/styled_text.dart';
import 'package:codedbykay_text_tv/model/text_tv_page.dart';
import 'package:codedbykay_text_tv/services/text_tv.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fakes/fake_http_fetcher.dart';

TextTvPage _fixture(int number, {bool styled = true}) {
  final String body = File('test/fixtures/texttv_$number.json')
      .readAsStringSync();
  final TextTvPage page = TextTv(fetcher: FakeHttpFetcher())
      .parse(number, body)!;
  return styled ? page : TextTvPage(number: number, parts: page.parts);
}

TextTvPage _plain(List<String> lines) =>
    TextTvPage(number: 200, parts: <List<String>>[lines]);

List<ReaderBlock> _blocks(List<String> lines) =>
    buildReaderBlocks(_plain(lines), 0);

String _describe(ReaderBlock b) => switch (b) {
  ReaderCaption() => 'caption: ${b.text}',
  ReaderHeading() =>
    'heading: ${b.text}${b.link == null ? '' : ' -> ${b.link}'}',
  ReaderParagraph() =>
    'text: ${b.text}${b.link == null ? '' : ' -> ${b.link}'}',
  ReaderColumns() => 'columns: ${b.left} | ${b.right}',
  ReaderNav() =>
    'nav: ${b.links.map((ReaderLink l) => '${l.label} ${l.page}').join(', ')}',
};

List<String> _lines(List<ReaderBlock> blocks) => blocks.map(_describe).toList();

void main() {
  group('on real pages', () {
    test('the front page: headlines, linked stories and the link row', () {
      expect(_lines(buildReaderBlocks(_fixture(100), 0)), <String>[
        'caption: 100 SVT Text lördag 26 sep 2026',
        'heading: Akilov i avskildhet efter två slagsmål',
        'text: Incidenter i fängelset med terroristen -> 107',
        'text: Fyra dödades i ryska attacker - tre döda i ukrainskt anfall -> 130',
        'heading: Erik Thedéens varning till regeringen: Ofinansierade löften - räntan höjs mer -> 111',
        'text: Sandviken: Grishuvud utanför moské -> 108',
        'nav: Inrikes 101, Utrikes 104, Innehåll 700',
      ]);
    });

    test('the same page from plain text alone loses only its headings', () {
      final List<String> lines = _lines(
        buildReaderBlocks(_fixture(100, styled: false), 0),
      );

      expect(lines, hasLength(7));
      expect(lines[1], 'text: Akilov i avskildhet efter två slagsmål');
      expect(lines[2], 'text: Incidenter i fängelset med terroristen -> 107');
      expect(lines[5], 'text: Sandviken: Grishuvud utanför moské -> 108');
      expect(lines.last, 'nav: Inrikes 101, Utrikes 104, Innehåll 700');
    });

    test('a news list: every item is a link, leader dots dropped', () {
      final List<String> lines = _lines(buildReaderBlocks(_fixture(104), 0));

      expect(lines, contains('text: Udda enighet i FN:s säkerhetsråd -> 130'));
      expect(lines, contains('text: Kanada: Byter namn på Trumpgata -> 133'));
      expect(
        lines,
        contains('text: Lämnade salen när Netanyahu talade -> 137'),
      );
      expect(lines.last, 'nav: Inrikes 101, Sport 300, Innehåll 700');
    });

    test('results: a banner, section titles and score rows as columns', () {
      final List<String> lines = _lines(buildReaderBlocks(_fixture(377), 0));

      expect(lines[1], 'heading: MÅLSERVICE');
      expect(lines[2], 'text: Fotboll Damallsvenskan');
      expect(lines[3], 'columns: Kristianstad - Vittsjö | 0 - 1 13:00');
      expect(lines, contains('columns: Malmö - Frölunda | X - X 18:00'));
      expect(lines.last, 'nav: Målserviceindex 376, Resultat 330');
    });

    test('a page whose parts do not exist reads as its last part', () {
      expect(buildReaderBlocks(_fixture(100), 9), isNotEmpty);
    });
  });

  group('the rules', () {
    test('a page with no parts gives nothing', () {
      expect(
        buildReaderBlocks(
          const TextTvPage(number: 100, parts: <List<String>>[]),
          0,
        ),
        isEmpty,
      );
    });

    test('lines that wrapped join into one paragraph', () {
      expect(
        _lines(
          _blocks(<String>[
            '  Regeringen lägger i dag fram ett',
            '  förslag om skärpta regler för',
            '  bidrag till kommunerna.',
          ]),
        ),
        <String>[
          'text: Regeringen lägger i dag fram ett förslag om skärpta regler för bidrag till kommunerna.',
        ],
      );
    });

    test('a short line ends its paragraph', () {
      expect(
        _lines(_blocks(<String>['Rubrik', 'Och här kommer brödtexten.'])),
        <String>['text: Rubrik', 'text: Och här kommer brödtexten.'],
      );
    });

    test('a blank row ends it too', () {
      expect(
        _lines(
          _blocks(<String>[
            'En lång rad som fyller ut hela bredden',
            '',
            'Nästa stycke börjar här och fortsätter',
          ]),
        ),
        <String>[
          'text: En lång rad som fyller ut hela bredden',
          'text: Nästa stycke börjar här och fortsätter',
        ],
      );
    });

    test('only the first row is a caption, and only if it looks like one', () {
      expect(
        _lines(_blocks(<String>['100 SVT Text måndag', 'Något annat'])).first,
        'caption: 100 SVT Text måndag',
      );
      expect(
        _lines(_blocks(<String>['Något annat', '100 SVT Text måndag'])),
        <String>['text: Något annat', 'text: 100 SVT Text måndag'],
      );
    });

    test('a bare number links the block above it', () {
      expect(_lines(_blocks(<String>['Rubriken här', '        245'])), <String>[
        'text: Rubriken här -> 245',
      ]);
    });

    test('a bare number with nothing above it is dropped', () {
      expect(_lines(_blocks(<String>['', '245', 'Text'])), <String>[
        'text: Text',
      ]);
    });

    test('a sentence ending in a number is a link on a plain page', () {
      expect(_lines(_blocks(<String>['Sport i dag.. 300'])), <String>[
        'text: Sport i dag -> 300',
      ]);
    });

    test('a link row needs two label-and-number pairs', () {
      expect(_lines(_blocks(<String>['Inrikes 101 Utrikes 104'])), <String>[
        'nav: Inrikes 101, Utrikes 104',
      ]);
      expect(
        _lines(_blocks(<String>['Det kostade 1 200 kr och 500 kr'])),
        <String>['text: Det kostade 1 200 kr och 500 kr'],
        reason: 'two numbers in a sentence are not a link row',
      );
    });

    test('a wide gap makes a table row, split at the last gap', () {
      expect(
        _lines(_blocks(<String>['AIK          - Växjö        X - X 15:00'])),
        <String>['columns: AIK - Växjö | X - X 15:00'],
      );
    });

    test('a tall row is a heading, and the plain line above is part of it', () {
      final TextTvPage page = TextTvPage(
        number: 200,
        parts: const <List<String>>[<String>[]],
        styledParts: <List<List<StyledRun>>>[
          <List<StyledRun>>[
            <StyledRun>[const StyledRun('Första halvan av rubriken')],
            <StyledRun>[const StyledRun('och andra halvan', tall: true)],
            <StyledRun>[const StyledRun('')],
            <StyledRun>[const StyledRun('   310')],
          ],
        ],
      );

      expect(_lines(buildReaderBlocks(page, 0)), <String>[
        'heading: Första halvan av rubriken och andra halvan -> 310',
      ]);
    });

    test('a colour bar with text is a heading, an empty one is nothing', () {
      final TextTvPage page = TextTvPage(
        number: 200,
        parts: const <List<String>>[<String>[]],
        styledParts: <List<List<StyledRun>>>[
          <List<StyledRun>>[
            <StyledRun>[StyledRun(''.padRight(40), bg: TvColor.blue)],
            <StyledRun>[StyledRun('  SPORT'.padRight(40), bg: TvColor.blue)],
          ],
        ],
      );

      expect(_lines(buildReaderBlocks(page, 0)), <String>['heading: SPORT']);
    });

    test(
      'where the site marked its links, a bare 500 at the end is no link',
      () {
        final TextTvPage page = TextTvPage(
          number: 200,
          parts: const <List<String>>[<String>[]],
          styledParts: <List<List<StyledRun>>>[
            <List<StyledRun>>[
              <StyledRun>[const StyledRun('Biljetten kostade 500')],
            ],
          ],
        );

        expect(_lines(buildReaderBlocks(page, 0)), <String>[
          'text: Biljetten kostade 500',
        ]);
      },
    );

    test('a link in the middle of a line stays a link in the text', () {
      final TextTvPage page = TextTvPage(
        number: 200,
        parts: const <List<String>>[<String>[]],
        styledParts: <List<List<StyledRun>>>[
          <List<StyledRun>>[
            <StyledRun>[
              const StyledRun('Läs mer på sidan '),
              const StyledRun('377', underline: true, command: '377'),
              const StyledRun(' om matchen.'),
            ],
          ],
        ],
      );

      final ReaderParagraph paragraph =
          buildReaderBlocks(page, 0).single as ReaderParagraph;

      expect(paragraph.link, isNull);
      expect(
        paragraph.spans.map((ReaderSpan s) => (s.text, s.page)).toList(),
        <(String, int?)>[
          ('Läs mer på sidan ', null),
          ('377', 377),
          (' om matchen.', null),
        ],
      );
    });

    test('block graphics are left out of the text', () {
      final TextTvPage page = TextTvPage(
        number: 200,
        parts: const <List<String>>[<String>[]],
        styledParts: <List<List<StyledRun>>>[
          <List<StyledRun>>[
            <StyledRun>[
              const StyledRun(' ', mosaic: <int>[1]),
              const StyledRun('Logotyp och text'),
            ],
          ],
        ],
      );

      expect(_lines(buildReaderBlocks(page, 0)), <String>[
        'text: Logotyp och text',
      ]);
    });
  });
}
