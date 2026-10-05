import 'dart:convert';
import 'dart:io';

import 'package:codedbykay_text_tv/model/text_tv_page.dart';
import 'package:codedbykay_text_tv/services/text_tv.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fakes/fake_http_fetcher.dart';

/// What else the site's answer says about a page: when it was changed, which
/// version it is, where it sits in the tree.
TextTvPage? _parse(Map<String, Object?> extras) {
  final String body = jsonEncode(<Object>[
    <String, Object?>{
      'num': '377',
      'content_plain': <String>['377 SVT Text'],
      'next_page': '378',
      'prev_page': '376',
      ...extras,
    },
  ]);
  return TextTv(fetcher: FakeHttpFetcher()).parse(377, body);
}

void main() {
  group('a real page', () {
    late TextTvPage page;
    setUp(() {
      page = TextTv(
        fetcher: FakeHttpFetcher(),
      ).parse(101, File('test/fixtures/texttv_101.json').readAsStringSync())!;
    });

    test('says when the site last changed it', () {
      expect(page.updatedUnix, 1791194523);
    });

    test('has the id of this version and the link that names it', () {
      expect(page.id, '37397934');
      expect(page.permalink, 'https://texttv.nu/101/inrikes-37397934');
    });

    test('has the way down from the start page', () {
      expect(page.breadcrumbs, const <Crumb>[
        Crumb('Hem', 100),
        Crumb('Inrikes', 101),
      ]);
    });
  });

  group('the extras are read tolerantly', () {
    test('a page that says none of it has none of it', () {
      final TextTvPage page = _parse(<String, Object?>{})!;

      expect(page.updatedUnix, isNull);
      expect(page.id, isNull);
      expect(page.permalink, isNull);
      expect(page.breadcrumbs, isNull);
    });

    test('a time given as text is read, nonsense is none', () {
      expect(
        _parse(<String, Object?>{'date_updated_unix': '123'})!.updatedUnix,
        123,
      );
      expect(
        _parse(<String, Object?>{'date_updated_unix': 'x'})!.updatedUnix,
        isNull,
      );
      expect(
        _parse(<String, Object?>{'date_updated_unix': <int>[]})!.updatedUnix,
        isNull,
      );
    });

    test('a link that is not the site\'s own is not kept', () {
      for (final Object? link in <Object?>[
        'http://texttv.nu/377/x-1',
        'https://evil.example/texttv.nu',
        'https://texttv.nu.evil.example/x',
        'javascript:alert(1)',
        '',
        42,
        null,
      ]) {
        expect(
          _parse(<String, Object?>{'permalink': link})!.permalink,
          isNull,
          reason: '$link',
        );
      }
      expect(
        _parse(<String, Object?>{'permalink': 'https://www.texttv.nu/377/a-1'})!
            .permalink,
        'https://www.texttv.nu/377/a-1',
      );
    });

    test('a crumb that is not a page of ours is dropped, not the rest', () {
      final TextTvPage page = _parse(<String, Object?>{
        'breadcrumbs': <Object?>[
          <String, Object?>{'name': 'Hem', 'num': '100'},
          <String, Object?>{'name': 'Fel', 'num': '5'},
          'nonsense',
          <String, Object?>{'name': 'Sport', 'num': '300'},
          <String, Object?>{'num': 'abc'},
        ],
      })!;

      expect(page.breadcrumbs, const <Crumb>[
        Crumb('Hem', 100),
        Crumb('Sport', 300),
      ]);
    });

    test('breadcrumbs that are not a list, or are empty, are none', () {
      expect(
        _parse(<String, Object?>{'breadcrumbs': 'x'})!.breadcrumbs,
        isNull,
      );
      expect(
        _parse(<String, Object?>{'breadcrumbs': <Object?>[]})!.breadcrumbs,
        isNull,
      );
    });

    test('crumbs are equal when name and page are', () {
      expect(const Crumb('A', 100), const Crumb('A', 100));
      expect(const Crumb('A', 100).hashCode, const Crumb('A', 100).hashCode);
      expect(const Crumb('A', 100), isNot(const Crumb('A', 101)));
    });
  });
}
