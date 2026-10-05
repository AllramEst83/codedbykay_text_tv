import 'dart:io';

import 'package:codedbykay_text_tv/model/fastext.dart';
import 'package:codedbykay_text_tv/model/text_tv_page.dart';
import 'package:codedbykay_text_tv/services/text_tv.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fakes/fake_http_fetcher.dart';

TextTvPage _fixture(int number) => TextTv(
  fetcher: FakeHttpFetcher(),
).parse(number, File('test/fixtures/texttv_$number.json').readAsStringSync())!;

TextTvPage _plain(List<String> lines, {int parts = 1}) => TextTvPage(
  number: 200,
  parts: <List<String>>[for (int i = 0; i < parts; i++) lines],
);

List<(FastextColour, String, int)> _described(List<FastextLink> links) =>
    links.map((FastextLink l) => (l.colour, l.label, l.page)).toList();

void main() {
  group('fastextLinks', () {
    test('the front page: its three bottom links', () {
      expect(
        _described(fastextLinks(_fixture(100), 0)),
        <(FastextColour, String, int)>[
          (FastextColour.red, 'Inrikes', 101),
          (FastextColour.green, 'Utrikes', 104),
          (FastextColour.yellow, 'Innehåll', 700),
        ],
      );
    });

    test('a news list, and a results page', () {
      expect(
        fastextLinks(_fixture(104), 0).map((FastextLink l) => l.page),
        <int>[101, 300, 700],
      );
      expect(
        fastextLinks(_fixture(377), 0).map((FastextLink l) => l.page),
        <int>[376, 330],
      );
    });

    test('at most four, in the colours of a remote', () {
      final List<FastextLink> links = fastextLinks(
        _plain(<String>['Text', 'A 101 B 102 C 103 D 104 E 105 F 106']),
        0,
      );

      expect(links.map((FastextLink l) => l.colour), FastextColour.values);
      expect(links.map((FastextLink l) => l.page), <int>[101, 102, 103, 104]);
    });

    test('blank rows under the link row are skipped', () {
      expect(
        fastextLinks(_plain(<String>['Text', 'A 101 B 102', '', '   ']), 0),
        hasLength(2),
      );
    });

    test('a last row that is not a link row gives none', () {
      expect(
        fastextLinks(_plain(<String>['Text', 'Bara en rad text']), 0),
        isEmpty,
      );
      expect(
        fastextLinks(_plain(<String>['A 101 B 102', 'Sist en vanlig rad']), 0),
        isEmpty,
        reason: 'only the last row counts',
      );
    });

    test('one link alone is not a row of keys', () {
      expect(fastextLinks(_plain(<String>['Text', 'Inrikes 101']), 0), isEmpty);
    });

    test('a number in a sentence is not a link row', () {
      expect(
        fastextLinks(_plain(<String>['Det kostade 1 200 kr och 500 kr']), 0),
        isEmpty,
      );
    });

    test('reads the part asked for', () {
      const TextTvPage page = TextTvPage(
        number: 200,
        parts: <List<String>>[
          <String>['Del ett', 'A 101 B 102'],
          <String>['Del två', 'C 301 D 302'],
        ],
      );

      expect(fastextLinks(page, 0).map((FastextLink l) => l.page), <int>[
        101,
        102,
      ]);
      expect(fastextLinks(page, 1).map((FastextLink l) => l.page), <int>[
        301,
        302,
      ]);
      expect(fastextLinks(page, 9).map((FastextLink l) => l.page), <int>[
        301,
        302,
      ]);
    });

    test('a page with no parts, or an empty one, gives none', () {
      expect(
        fastextLinks(const TextTvPage(number: 1, parts: <List<String>>[]), 0),
        isEmpty,
      );
      expect(fastextLinks(_plain(<String>['', '']), 0), isEmpty);
    });
  });
}
