import 'dart:io';

import 'package:codedbykay_text_tv/model/prefetch.dart';
import 'package:codedbykay_text_tv/model/text_tv_page.dart';
import 'package:codedbykay_text_tv/services/text_tv.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fakes/fake_http_fetcher.dart';

TextTvPage _fixture(int number) => TextTv(
  fetcher: FakeHttpFetcher(),
).parse(number, File('test/fixtures/texttv_$number.json').readAsStringSync())!;

TextTvPage _page(
  int number, {
  int? previous,
  int? next,
  List<String> lines = const <String>['Text'],
}) => TextTvPage(
  number: number,
  parts: <List<String>>[lines],
  previous: previous,
  next: next,
);

void main() {
  group('prefetchTargets', () {
    test('the next page first, then the one before', () {
      expect(prefetchTargets(_page(300, previous: 299, next: 301), 0), <int>[
        301,
        299,
      ]);
    });

    test('follows the neighbours the site names, not just the numbers', () {
      expect(prefetchTargets(_page(104, previous: 101, next: 130), 0), <int>[
        130,
        101,
      ]);
    });

    test('without named neighbours it uses the numbers either side', () {
      expect(prefetchTargets(_page(300), 0), <int>[301, 299]);
    });

    test('then the pages the bottom row links to', () {
      expect(
        prefetchTargets(
          _page(
            300,
            previous: 299,
            next: 301,
            lines: <String>['Text', 'Sport 310 Väder 400'],
          ),
          0,
        ),
        <int>[301, 299, 310, 400],
      );
    });

    test('and the links in the text, from a page the site coloured', () {
      final List<int> targets = prefetchTargets(_fixture(100), 0);

      // 100's neighbours, then its stories in the order it lists them.
      expect(targets.first, 101);
      expect(targets, contains(107));
      expect(targets, contains(130));
    });

    test('never more than the limit, however many links', () {
      final TextTvPage many = _page(
        300,
        lines: <String>['Text', 'A 401 B 402 C 403 D 404 E 405 F 406'],
      );

      expect(prefetchTargets(many, 0), hasLength(prefetchLimit));
      expect(prefetchTargets(many, 0, limit: 2), hasLength(2));
      expect(prefetchLimit, lessThanOrEqualTo(4));
    });

    test('each page once, and never the page itself', () {
      final List<int> targets = prefetchTargets(
        _page(
          300,
          previous: 299,
          next: 301,
          lines: <String>['Text', 'Själv 300 Nästa 301 Före 299 Annan 500'],
        ),
        0,
      );

      expect(targets, <int>[301, 299, 500]);
    });

    test('only real page numbers: nothing past 100 or 899', () {
      expect(prefetchTargets(_page(100, previous: 99, next: 101), 0), <int>[
        101,
      ]);
      expect(prefetchTargets(_page(899, previous: 898, next: 900), 0), <int>[
        898,
      ]);
    });

    test('reads the part being shown', () {
      const TextTvPage page = TextTvPage(
        number: 300,
        parts: <List<String>>[
          <String>['Del ett', 'A 111 B 112'],
          <String>['Del två', 'C 221 D 222'],
        ],
        previous: 299,
        next: 301,
      );

      expect(prefetchTargets(page, 0), <int>[301, 299, 111, 112]);
      expect(prefetchTargets(page, 1), <int>[301, 299, 221, 222]);
    });

    test('a page with no parts still has its neighbours', () {
      expect(
        prefetchTargets(
          const TextTvPage(number: 300, parts: <List<String>>[]),
          0,
        ),
        <int>[301, 299],
      );
    });
  });
}
